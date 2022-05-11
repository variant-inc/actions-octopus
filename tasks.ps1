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

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Scope = 'Function')]
$variantApiDeployYamlPath = [System.IO.Path]::GetFullPath((Join-Path ${RepositoryRoot} ".variant/deploy/"))

if ((Test-Path -Path $variantApiDeployYamlPath) -eq $true) {
  $deployYamlsFound = Get-ChildItem -Path $variantApiDeployYamlPath -Filter "*.yaml" -Recurse
}
else {
  Write-Output "`e[31m________________________________________________________________`e[0m";
  Write-Output "`e[31mDeploy folder does not exists in .variant directory`e[0m";
  Write-Output "`e[31m________________________________________________________________`e[0m";
  exit 1
}

if ($deployYamlsFound.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path "/tmp/$env:GITHUB_REPOSITORY"
  Set-Location "/tmp/$env:GITHUB_REPOSITORY"

  dotnet nuget add source --name cake --username "${NugetUser}" --password "${NugetToken}" --store-password-in-clear-text "https://nuget.pkg.github.com/variant-inc/index.json"
  ce dotnet nuget update source cake -u "${NugetUser}" -p "${NugetToken}" --store-password-in-clear-text -s "https://nuget.pkg.github.com/variant-inc/index.json"
  ce dotnet new tool-manifest --force
  ce dotnet tool install --version "${TaskRunnerVersion}" --no-cache Variant.Cake.Runner
  ce dotnet variant-cake-runner --target CreateRelease --path $variantApiDeployYamlPath
  Exit
}