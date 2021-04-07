$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap
{
  Write-Error $_ -ErrorAction Continue
  exit 1
}
function CommandAliasFunction
{
  Write-Information ""
  Write-Information "$args"
  $cmd, $args = $args
  & "$cmd" $args
  if ($LASTEXITCODE)
  {
    throw "Exception Occured"
  }
  Write-Information ""
}

Set-Alias -Name ce -Value CommandAliasFunction -Scope script

$octoYamlPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ".octopus/workflow/octopus.yaml"))
if (Test-Path -Path $octoYamlPath -PathType Leaf)
{
  $SPACE_NAME = ce yq eval .SpaceName $octoYamlPath
  $PROJECT_NAME = ce yq eval .ProjectName $octoYamlPath
} else {
  $SPACE_NAME = $env:SPACE_NAME
  $PROJECT_NAME = $env:PROJECT_NAME
}

if (($null -eq $SPACE_NAME) -or ("" -eq $SPACE_NAME))
{
  throw "Space Name not provided"
}

if (($null -eq $PROJECT_NAME) -or ("" -eq $PROJECT_NAME))
{
  throw "Project Name not provided"
}

if (${env:GITVERSION_BRANCHNAME} -eq "${env:DEFAULT_BRANCH}")
{
  $channelName = "release"
}
elseif (${env:GITVERSION_BRANCHNAME} -match "${env:FEATURE_CHANNEL_BRANCHES}")
{
  $channelName = "feature"
} else {
  exit 0;
}

$deployScriptsPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ${env:DEPLOY_SCRIPTS_PATH}))

mkdir -p ./packages/
ce octo pack --id="${PROJECT_NAME}" `
  --format="Zip" --version="${env:VERSION}" `
  --basePath="$deployScriptsPath" --outFolder="./packages"

ce octo push --package="./packages/${PROJECT_NAME}.${env:VERSION}.zip" `
  --space="${SPACE_NAME}" `
  --overwrite-mode=OverwriteExisting

$commitMessage = git log -1 --pretty=oneline
$commitMessage = $commitMessage -replace "${env:GITHUB_SHA} ", ""
Write-Information "Commit Message: $commitMessage"
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

New-Item "buildinformation.json" -ItemType File
Set-Content -Path "buildinformation.json" -Value $jsonBody

ce octo build-information `
  --package-id="${PROJECT_NAME}" `
  --file="buildinformation.json" `
  --version="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --overwrite-mode=OverwriteExisting

octo create-release `
  --project="${PROJECT_NAME}" `
  --packageVersion="${env:VERSION}" `
  --releaseNumber="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --channel="$channelName"