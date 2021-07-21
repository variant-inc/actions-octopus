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

Write-Output "Pushing Octopus Package"
ce octo push --package="./packages/${PROJECT_NAME}.${env:VERSION}.zip" `
  --space="${SPACE_NAME}" `
  --overwrite-mode=OverwriteExisting

$commitMessage = git log -1 --pretty=oneline
$commitMessage = $commitMessage -replace "${env:GITHUB_SHA} ", ""
Write-Information "Commit Message: $commitMessage"
Write-Output "Writing Build Information"
$jsonBody = @{
  BuildEnvironment = "GitHub Actions"
  Branch           = "${env:GITVERSION_BRANCHNAME}"
  BuildNumber      = "${env:GITHUB_RUN_NUMBER}"
  BuildUrl         = "https://github.com/${env:GITHUB_REPOSITORY}/actions/runs/${env:GITHUB_RUN_ID}"
  VcsCommitNumber  = "${env:GITHUB_SHA}"
  VcsType          = "Git"
  VcsRoot          = "https://github.com/${env:GITHUB_REPOSITORY}.git"
  Commits          = @(
    @{
      Id      = "${env:GITHUB_SHA}"
      LinkUrl = "https://github.com/${env:GITHUB_REPOSITORY}/commit/${env:GITHUB_SHA}"
      Comment = "$commitMessage"
    }
  )
} | ConvertTo-Json -Depth 10 -Compress

New-Item "buildinformation.json" -ItemType File -Force
Set-Content -Path "buildinformation.json" -Value $jsonBody

Write-Output "Pushing Build Information"
ce octo build-information `
  --package-id="${PROJECT_NAME}" `
  --file="buildinformation.json" `
  --version="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --overwrite-mode=OverwriteExisting

Write-Output "Creating Octopus Release"
ce octo create-release `
  --project="${PROJECT_NAME}" `
  --packageVersion="${env:VERSION}" `
  --releaseNumber="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --channel="$channelName" `
  --ignoreExisting