$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap {
  Write-Error $_.InvocationInfo.ScriptName -ErrorAction Continue
  $line = "$($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"
  Write-Error $line -ErrorAction Continue
  Write-Error $_
}

Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module Native
Import-Module Native

$DeployYamlDir = [System.IO.Path]::GetFullPath($env:DEPLOY_YAML_DIR)
$MagePath = $env:MAGE_PATH

if ((Test-Path -Path $DeployYamlDir) -eq $true) {
  $deployYamlsFound = Get-ChildItem `
    -Path "${DeployYamlDir}/*.*" `
    -Include ('*.yml', '*.yaml')
}
else {
  throw "::error::Deploy folder does not exist in $env:DEPLOY_YAML_DIR directory"
}

if ($deployYamlsFound.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path "/tmp/$env:GITHUB_REPOSITORY" | Out-Null
  Set-Location "/tmp/$env:GITHUB_REPOSITORY"
  $env:TMP_PATH = "/tmp"

  dotnet nuget add source --name octopus --username "optional" --password $env:AZ_DEVOPS_PAT --store-password-in-clear-text "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json"
  dotnet nuget update source octopus -u "optional" -p $env:AZ_DEVOPS_PAT --store-password-in-clear-text -s "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json"

  New-Item -ItemType File -Path ./.config/dotnet-tools.json -Force | Out-Null
  Copy-Item $env:GITHUB_ACTION_PATH/.config/dotnet-tools.json ./.config/dotnet-tools.json -Force | Out-Null

  if ([regex]::match($env:TF_APPS_VERSION, '[\[\]()]').Success) {
    $message = $(& dotnet tool install --version $env:TF_APPS_VERSION --no-cache terraform-variant-apps ) 2>&1
    $env:TF_APPS_VERSION = [regex]::match($message, '\d+\.\d+\.\d+').Groups[0].Value
  }
  Write-Host "terraform-variant-apps version: $env:TF_APPS_VERSION"

  $deployYamlsFound | ForEach-Object -Parallel {
    ins "$MagePath octopus:octoPush $($_.FullName)" -ErrorOnFailure
  }
}
else {
  throw "::error::No Deploy files (.yaml|.yml) files found in $env:DEPLOY_YAML_DIR"
}
