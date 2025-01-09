Write-Output "Gathering Space/Project from workflow input"
$SPACE_NAME = $env:SPACE_NAME
$PROJECT_NAME = $env:PROJECT_NAME

if (($null -eq $SPACE_NAME) -or ("" -eq $SPACE_NAME))
{
  throw "Space Name not provided"
}

if (($null -eq $PROJECT_NAME) -or ("" -eq $PROJECT_NAME))
{
  throw "Project Name not provided"
}

if (${env:GitVersion_BranchName} -eq "${env:DEFAULT_BRANCH}")
{
  $channelName = "release"
}
elseif (${env:GitVersion_BranchName} -match "${env:FEATURE_CHANNEL_BRANCHES}")
{
  $channelName = "feature"
}
else
{
  exit 0;
}

$deployScriptsPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ${env:DEPLOY_SCRIPTS_PATH}))

mkdir -p ./packages/

Write-Output "Packing Octopus Package"
ce octopus package zip create --id="${PROJECT_NAME}" `
  --version="${env:VERSION}" `
  --base-path="$deployScriptsPath" --out-folder="./packages" `
  --no-prompt

Write-Output "Pushing Octopus Package"
ce octopus package upload --package="./packages/${PROJECT_NAME}.${env:VERSION}.zip" `
  --space="${SPACE_NAME}" `
  --overwrite-mode="overwrite" `
  --no-prompt

$releaseNotes = ""
$events = Get-Content $env:GITHUB_EVENT_PATH | ConvertFrom-Json
if ($null -ne $events.commits) {
  $events.commits | ForEach-Object {
    $releaseNotes += @"
____________________
#### [commit $($_.id)](https://github.com/$GITHUB_REPOSITORY/commit/$($_.id))

**Author:** $($_.author.name) - $($_.author.name) <$($_.author.email)>

**Committer:** $($_.committer.name) - $($_.committer.name) <$($_.committer.email)>

**Date:**   $($_.timestamp)

<br/>`+"\n``````"+`text
$($_.message)`+"\n``````\n<br/>"
"@
  }
}

Write-Output "Creating Octopus Release"
ce octopus release create `
  --project="${PROJECT_NAME}" `
  --package-version="${env:VERSION}" `
  --version="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --channel="$channelName" `
  --ignore-existing `
  --no-prompt `
  --release-notes $releaseNotes
