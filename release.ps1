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

$commitMessage = git log -1 --pretty=oneline
$commitMessage = $commitMessage -replace "${env:GITHUB_SHA} ", ""
Write-Information "Commit Message: $commitMessage"

Write-Output "Creating Octopus Release"
ce octopus release create `
  --project="${PROJECT_NAME}" `
  --package-version="${env:VERSION}" `
  --version="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --channel="$channelName" `
  --ignore-existing `
  --no-prompt
