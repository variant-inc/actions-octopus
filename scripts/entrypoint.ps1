$ErrorActionPreference = "Stop"

$gitVersion = $(dotnet-gitversion | ConvertFrom-Json)

$channelName = "release"
if ($($gitVersion.BranchName) -ne "${env:INPUT_DEFAULT_BRANCH}")
{
  $channelName = "feature"
}

$deployScriptsPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ${env:INPUT_DEPLOY_SCRIPTS_PATH}))

mkdir -p ./packages/
octo pack --id="${env:INPUT_PROJECT_NAME}" `
  --format="Zip" --version="${env:INPUT_PACKAGE_VERSION}" `
  --basePath="$deployScriptsPath " --outFolder="./packages"

octo push --package="./packages/${env:INPUT_PROJECT_NAME}.${env:INPUT_PACKAGE_VERSION}.zip" `
  --space="${env:INPUT_OCTOPUS_SPACE_NAME}"

$commitMessage = git log -1 --pretty=oneline
$commitMessage = $commitMessage -replace "${env:GITHUB_SHA} ", ""
Write-Information "Commit Message: $commitMessage"
$jsonBody = @{
  BuildEnvironment = "GitHub Actions"
  Branch           = "$($gitVersion.BranchName)"
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

New-Item "buildinformation.json" -ItemType File
Set-Content -Path "buildinformation.json" -Value $jsonBody

octo build-information `
  --package-id="${env:INPUT_PROJECT_NAME}" `
  --file="buildinformation.json" `
  --version="${env:INPUT_PACKAGE_VERSION}" `
  --space="${env:INPUT_OCTOPUS_SPACE_NAME}"

octo create-release `
  --project="${env:INPUT_PROJECT_NAME}" `
  --packageVersion="${env:INPUT_PACKAGE_VERSION}" `
  --releaseNumber="${env:INPUT_PACKAGE_VERSION}" `
  --space="${env:INPUT_OCTOPUS_SPACE_NAME}" `
  --channel="$channelName"