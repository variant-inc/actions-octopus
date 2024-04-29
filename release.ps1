if (Test-Path -Path $octoYamlPath -PathType Leaf)
{
  Write-Output "Gathering Space/Project from octopus.yaml"
  $SPACE_NAME = ce yq eval .SpaceName $octoYamlPath
  $PROJECT_NAME = ce yq eval .ProjectName $octoYamlPath
}
else
{
  Write-Output "Gathering Space/Project from workflow input"
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
Write-Output "Writing Build Information"
$jsonBody = @{
  BuildEnvironment = "actions-octopus:v1"
  Branch           = "${env:GitVersion_BranchName}"
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

Write-Output "Creating Octopus Release"
ce octopus release create `
  --project="${PROJECT_NAME}" `
  --package-version="${env:VERSION}" `
  --version="${env:VERSION}" `
  --space="${SPACE_NAME}" `
  --channel="$channelName" `
  --ignore-existing `
  --no-prompt
