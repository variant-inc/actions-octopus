if (${env:GITVERSION_BRANCHNAME} -eq "${env:DEFAULT_BRANCH}")
{
  $channelName = "release"
}
elseif (${env:GITVERSION_BRANCHNAME} -match "${env:FEATURE_CHANNEL_BRANCHES}")
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
ce octo pack --id="${PROJECT_NAME}" `
  --format="Zip" --version="${env:VERSION}" `
  --basePath="$deployScriptsPath" --outFolder="./packages"
Get-ChildItem ./packages/
Write-Output "Pushing Octopus Package"
ce octo push --package="./packages/${PROJECT_NAME}.${env:VERSION}.zip" `
  --space="${SPACE_NAME}" `
  --overwrite-mode=OverwriteExisting

$eventPayload = Get-Content $env:GITHUB_EVENT_PATH | ConvertFrom-Json
$commits = [System.Collections.ArrayList]@()
if ($null -ne $eventPayload.commits)
{
  $eventPayload.commits | ForEach-Object {
    $commits.Add(
      @{
        Id      = $_.id
        LinkUrl = $_.url
        Comment = $_.message
      }
    )
  }
}
else
{
  $commitMessage = git log -1 --pretty=oneline
  $commitMessage = $commitMessage -replace "${env:GITHUB_SHA} ", ""
  Write-Information "Commit Message: $commitMessage"
  $commits.Add(
    @{
      Id      = "${env:GITHUB_SHA}"
      LinkUrl = "https://github.com/${env:GITHUB_REPOSITORY}/commit/${env:GITHUB_SHA}"
      Comment = "$commitMessage"
    }
  )
}

Write-Output "Writing Build Information"
@{
  Version          = "${env:VERSION}"
  BuildEnvironment = "GitHub Actions"
  BuildNumber      = "${env:GITHUB_RUN_NUMBER}"
  BuildUrl         = "https://github.com/${env:GITHUB_REPOSITORY}/actions/runs/${env:GITHUB_RUN_ID}"
  Branch           = "${env:GITVERSION_BRANCHNAME}"
  VcsType          = "Git"
  VcsRoot          = "https://github.com/${env:GITHUB_REPOSITORY}.git"
  VcsCommitNumber  = "${env:GITHUB_SHA}"
  VcsCommitUrl     = "https://github.com/${env:GITHUB_REPOSITORY}/commit/${env:GITHUB_SHA}"
  Commits          = $commits
} | ConvertTo-Json -Depth 10 -Compress | Out-File -FilePath "buildinformation.json"

Get-Content "buildinformation.json"

Write-Output "Pushing Build Information"
ce octo build-information `
  --package-id="${PROJECT_NAME}" `
  --file="buildinformation.json" `
  --version="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --overwrite-mode=OverwriteExisting

$releaseNotes = ""
if ($null -ne $eventPayload.commits)
{
  Write-Output "Writing Release Notes"
  $eventPayload.commits | ForEach-Object {
    $releaseNotes += @"
____________________

#### commit $($_.id)

**Author:** $($_.author.username) - $($_.author.name) <$($_.author.email)>

**Committer:** $($_.committer.username) - $($_.committer.name) <$($_.committer.email)>

**Date:**   $(Get-Date $_.timestamp -Format "dddd MM/dd/yyyy HH:mm K")

<br/>

``````text
$($_.message)
``````
<br/>

"@
  }
}

$releaseNotes | Out-File -FilePath "releasenotes.txt"

Write-Output "Creating Octopus Release"
ce octo create-release `
  --project="${PROJECT_NAME}" `
  --packageVersion="${env:VERSION}" `
  --releaseNumber="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --channel="$channelName" `
  --ignoreExisting `
  --releaseNotesFile="releasenotes.txt"