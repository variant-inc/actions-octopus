$NugetUser = $env:GITHUB_ACTOR
$NugetToken = $env:AZ_DEVOPS_PAT
$CakeRunnerVersion = $env:CAKE_RUNNER_VERSION

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

  dotnet nuget add source --name cake --username "${NugetUser}" --password "${NugetToken}" --store-password-in-clear-text "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json"
  dotnet nuget update source cake -u "${NugetUser}" -p "${NugetToken}" --store-password-in-clear-text -s "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json"
  ce dotnet new tool-manifest --force

  [pscredential]$cred = New-Object System.Management.Automation.PSCredential ($NugetUser, $(ConvertTo-SecureString $NugetToken -AsPlainText -Force))
  Register-PackageSource -Name "cake" -Credential $cred -Location "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json" -ProviderName "NuGet" -Trusted
  if ($env:INPUT_DEPLOY_PACKAGE_VERSION.length -eq 0){
    $message = dotnet tool install --no-cache terraform-variant-apps
  } elseif ([regex]::match($env:INPUT_DEPLOY_PACKAGE_VERSION,'[\[\]()]').Success) {
    $message = dotnet tool install --version "${env:INPUT_DEPLOY_PACKAGE_VERSION}" --no-cache terraform-variant-apps
    $env:INPUT_DEPLOY_PACKAGE_VERSION = [regex]::match($message,'\d+\.\d+\.\d+').Groups[0].Value
  }

  if ($CakeRunnerVersion) {
    ce dotnet tool install --version "${CakeRunnerVersion}" --no-cache Variant.Cake.Runner
  } else {
    ce dotnet tool install --no-cache Variant.Cake.Runner
  }
  $CakeRunnerVersion = (Get-Content .config/dotnet-tools.json | ConvertFrom-Json).tools."variant.cake.runner".version
  ce dotnet variant-cake-runner `
    --target CreateRelease `
    --cakeRunnerVersion $CakeRunnerVersion `
    --deployYamlDirPath $variantApiDeployYamlPath `
    --logLevel $CakeLogLevel `
    --seriloglevel $SerilogLogLevel
}
else
{
  throw "::error::No Deploy files (.yaml|.yml) files found in .variant folder"
}
