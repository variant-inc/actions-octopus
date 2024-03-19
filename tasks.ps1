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

# function CommandAliasFunction {
#   Write-Information ""
#   Write-Information "$args"
#   $cmd, $args = $args
#   & "$cmd" $args
#   if ($LASTEXITCODE) {
#     throw "Exception Occured"
#   }
#   Write-Information ""
# }

# Set-Alias -Name ce -Value CommandAliasFunction -Scope script

$DeployYamlDir = [System.IO.Path]::GetFullPath($env:DEPLOY_YAML_DIR)

if ((Test-Path -Path $DeployYamlDir) -eq $true) {
  $deployYamlsFound = Get-ChildItem `
    -Path "${DeployYamlDir}/*.*" `
    -Include ('*.yml', '*.yaml')
}
else {
  throw "::error::Deploy folder does not exists in $env:DEPLOY_YAML_DIR directory";
}

if ($deployYamlsFound.Count -gt 0) {
  New-Item -ItemType Directory -Force -Path "/tmp/$env:GITHUB_REPOSITORY" | Out-Null
  Set-Location "/tmp/$env:GITHUB_REPOSITORY"
  $env:TMP_PATH = "/tmp"

  dotnet nuget add source --name octopus --username "optional" --password $env:AZ_DEVOPS_PAT --store-password-in-clear-text "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json"
  dotnet nuget update source octopus -u "optional" -p $env:AZ_DEVOPS_PAT --store-password-in-clear-text -s "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json"

  New-Item -ItemType File -Path ./.config/dotnet-tools.json -Force
  Copy-Item $env:GITHUB_ACTION_PATH/.config/dotnet-tools.json ./.config/dotnet-tools.json -Force
  # ce dotnet new tool-manifest --force
  # [pscredential]$cred = New-Object System.Management.Automation.PSCredential ("optional", $(ConvertTo-SecureString $env:AZ_DEVOPS_PAT -AsPlainText -Force))
  # Register-PackageSource -Name "octopus" -Credential $cred -Location "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json" -ProviderName "NuGet" -Trusted

  if ($env:TF_APPS_VERSION.length -eq 0) {
    $message = dotnet tool install --no-cache terraform-variant-apps
  }
  elseif ([regex]::match($env:TF_APPS_VERSION, '[\[\]()]').Success) {
    $message = $(& dotnet tool install --version $env:TF_APPS_VERSION --no-cache terraform-variant-apps ) 2>&1
    $env:TF_APPS_VERSION = [regex]::match($message, '\d+\.\d+\.\d+').Groups[0].Value
  }
  Write-Host "terraform-variant-apps version: $env:TF_APPS_VERSION"

  if ($env:MAGE_RUNNER_VERSION.length -eq 0) {
    $message = dotnet tool install --no-cache mage-runner
  }
  elseif ([regex]::match($env:MAGE_RUNNER_VERSION, '[\[\]()]').Success) {
    $message = $(& dotnet tool install --version "${env:MAGE_RUNNER_VERSION}" --no-cache mage-runner ) 2>&1
    $env:MAGE_RUNNER_VERSION = [regex]::match($message, '\d+\.\d+\.\d+').Groups[0].Value
  }
  Write-Host "mage-runner version: $env:MAGE_RUNNER_VERSION"

  nuget sources Add `
    -Name octopus `
    -Source https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json `
    -UserName "github-runner" `
    -Password $env:AZ_DEVOPS_PAT

  ie nuget install mage-runner `
    -Source octopus `
    -OutputDirectory mage `
    -Version $env:MAGE_RUNNER_VERSION

  Move-Item -Path ./mage/*/mage -Destination ./mage/
  chmod +x ./mage/mage

  $deployYamlsFound | ForEach-Object -Parallel {
    ins "./mage/mage octopus:octoPush $($_.FullName)"
  }
}
else {
  throw "::error::No Deploy files (.yaml|.yml) files found in .variant folder"
}
