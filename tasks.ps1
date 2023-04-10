<<<<<<< HEAD
$NugetUser = $env:GITHUB_ACTOR
$NugetToken = $env:GITHUB_TOKEN
$TaskRunnerVersion = $env:TASK_RUNNER_VERSION
=======
[CmdLetBinding()]
[Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidGlobalVars", '')]
Param(
  $NugetUser = $env:GITHUB_ACTOR,
  $NugetToken = $env:AZ_DEVOPS_PAT,
  $RepositoryRoot = $env:GITHUB_WORKSPACE,
  $TaskRunnerVersion = $env:INPUT_TASK_RUNNER_VERSION
)
>>>>>>> 760ea12 (move cake-runner to az devops)

$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap
{
  Write-Error $_.InvocationInfo.ScriptName -ErrorAction Continue
  $line = "$($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"
  Write-Error $line -ErrorAction Continue
  Write-Error $_
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

$variantApiDeployYamlPath = [System.IO.Path]::GetFullPath(".variant/deploy/")

if ((Test-Path -Path $variantApiDeployYamlPath) -eq $true)
{
  $deployYamlsFound = Get-ChildItem `
    -Path $variantApiDeployYamlPath `
    -Filter "*.*ml" -Recurse `
  | Where-Object { $_.Name -match ".(yaml|yml)" }
}
else
{
  throw "::error::Deploy folder does not exists in .variant directory";
}

if ($deployYamlsFound.Count -gt 0)
{
  New-Item -ItemType Directory -Force -Path "/tmp/$env:GITHUB_REPOSITORY" | Out-Null
  Set-Location "/tmp/$env:GITHUB_REPOSITORY"
  $env:TMP_PATH = "/tmp"
  $CakeLogLevel = if ($env:CAKE_LOG_LEVEL)
  {
    $env:CAKE_LOG_LEVEL
  }
  else
  {
    "Information"
  };
  $SerilogLogLevel = if ($env:SERILOG_LOG_LEVEL)
  {
    $env:SERILOG_LOG_LEVEL
  }
  else
  {
    "Information"
  };

  dotnet nuget add source --name cake --username "${NugetUser}" --password "${NugetToken}" --store-password-in-clear-text "https://pkgs.dev.azure.com/USXpress-Inc/Octopus/_packaging/Octopus/nuget/v3/index.json"
  ce dotnet nuget update source cake -u "${NugetUser}" -p "${NugetToken}" --store-password-in-clear-text -s "https://pkgs.dev.azure.com/USXpress-Inc/Octopus/_packaging/Octopus/nuget/v3/index.json"
  ce dotnet new tool-manifest --force

  if ($TaskRunnerVersion) {
    ce dotnet tool install --version "${TaskRunnerVersion}" --no-cache Variant.Cake.Runner
  } else {
    ce dotnet tool install --no-cache Variant.Cake.Runner
  }
  $TaskRunnerVersion = (Get-Content .config/dotnet-tools.json | ConvertFrom-Json).tools."variant.cake.runner".version
  ce dotnet variant-cake-runner `
    --target CreateRelease `
    --taskRunnerVersion $TaskRunnerVersion `
    --deployYamlDirPath $variantApiDeployYamlPath `
    --logLevel $CakeLogLevel `
    --seriloglevel $SerilogLogLevel
}
else
{
  throw "::error::No Deploy files (.yaml|.yml) files found in .variant folder"
}
