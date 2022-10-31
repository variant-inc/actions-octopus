[CmdLetBinding()]
[Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidGlobalVars", '')]
Param(
  $NugetUser = $env:GITHUB_ACTOR,
  $NugetToken = $env:GITHUB_PACKAGES_TOKEN,
  $RepositoryRoot = $env:GITHUB_WORKSPACE,
  $TaskRunnerVersion = $env:INPUT_TASK_RUNNER_VERSION
)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap {
  Write-Error $_.InvocationInfo.ScriptName -ErrorAction Continue
  $line = "$($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"
  Write-Error $line -ErrorAction Continue
  Write-Error $_
}
function CommandAliasFunction {
  Write-Information ""
  Write-Information "$args"
  $cmd, $args = $args
  & "$cmd" $args
  if ($LASTEXITCODE) {
    throw "Exception Occured"
  }
  Write-Information ""
}

Set-Alias -Name ce -Value CommandAliasFunction -Scope script

Write-Output "Starting Sonar check"
if ($env:INPUT_DEFAULT_BRANCH -eq $env:GITVERSION_BRANCHNAME){
  $sonarCheckUrl = "https://sonarcloud.io/api/qualitygates/project_status?projectKey=$env:SONAR_PROJECT_KEY&branch=$env:GITVERSION_BRANCHNAME"
  $headers = @{
    'Authorization' = 'Bearer ' + $env:SONAR_TOKEN
    'Accept'        = 'application/json'
  }
  try {
    $Response = Invoke-RestMethod -Uri $sonarCheckUrl -Headers $headers -Method GET
    $Response | ConvertTo-Json
    if ($Response.projectStatus.status -eq "OK") {
      Write-Output "Sonnar scan quality gate passed. Continuing with the deployment."
    } else {
      Write-Output "Sonnar scan quality gate failed. Stopping the deployment."
      exit 1
    }
  }
  catch {
    Write-Output "Skipping sonar check as project: $env:SONAR_PROJECT_KEY doesn't exist."
  }
}
Write-Output "Sonar check done"

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Scope = 'Function')]
$variantApiDeployYamlPath = [System.IO.Path]::GetFullPath((Join-Path ${RepositoryRoot} ".variant/deploy/"))

if ((Test-Path -Path $variantApiDeployYamlPath) -eq $true) {
  $deployYamlsFound = Get-ChildItem -Path $variantApiDeployYamlPath -Filter "*.yaml" -Recurse
}
else {
  Write-Output "`e[31m----------------------------------------------------------------`e[0m";
  Write-Output "`e[31mDeploy folder does not exists in .variant directory`e[0m";
  Write-Output "`e[31m----------------------------------------------------------------`e[0m";
  exit 1
}

if ($deployYamlsFound.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path "/tmp/$env:GITHUB_REPOSITORY"
  Set-Location "/tmp/$env:GITHUB_REPOSITORY"
  $env:TMP_PATH = "/tmp"
  $CakeLogLevel = if ($env:CAKE_LOG_LEVEL) { $env:CAKE_LOG_LEVEL } else { "Information" };
  $SerilogLogLevel = if ($env:SERILOG_LOG_LEVEL) { $env:SERILOG_LOG_LEVEL } else { "Information" };

  dotnet nuget add source --name cake --username "${NugetUser}" --password "${NugetToken}" --store-password-in-clear-text "https://nuget.pkg.github.com/variant-inc/index.json"
  ce dotnet nuget update source cake -u "${NugetUser}" -p "${NugetToken}" --store-password-in-clear-text -s "https://nuget.pkg.github.com/variant-inc/index.json"
  ce dotnet new tool-manifest --force

  ce dotnet tool install --version "${TaskRunnerVersion}" --no-cache Variant.Cake.Runner
  ce dotnet variant-cake-runner `
    --target CreateRelease `
    --taskRunnerVersion $TaskRunnerVersion `
    --deployYamlDirPath $variantApiDeployYamlPath `
    --logLevel $CakeLogLevel `
    --seriloglevel $SerilogLogLevel
  Exit
}
