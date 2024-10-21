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

  New-Item -ItemType File -Path ./.config/dotnet-tools.json -Force | Out-Null
  Copy-Item $env:GITHUB_ACTION_PATH/.config/dotnet-tools.json ./.config/dotnet-tools.json -Force | Out-Null

  if ([regex]::match($env:TF_APPS_VERSION, '[\[\]()]').Success) {
    $message = $(& dotnet tool install --version $env:TF_APPS_VERSION --no-cache terraform-variant-apps ) 2>&1
    $env:TF_APPS_VERSION = [regex]::match($message, '\d+\.\d+\.\d+').Groups[0].Value
  }
  Write-Host "terraform-variant-apps version: $env:TF_APPS_VERSION"

  if ([regex]::match($env:MAGE_RUNNER_VERSION, '[\[\]()]').Success) {
    $message = $(& dotnet tool install --version "${env:MAGE_RUNNER_VERSION}" --no-cache mage-runner ) 2>&1
    $env:MAGE_RUNNER_VERSION = [regex]::match($message, '\d+\.\d+\.\d+').Groups[0].Value
  }
  Write-Host "mage-runner version: $env:MAGE_RUNNER_VERSION"

  # nuget sources Add `
  #   -Name octopus `
  #   -Source https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json `
  #   -UserName "github-runner" `
  #   -Password $env:AZ_DEVOPS_PAT

  dotnet nuget add source "https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json" `
  --name octopus `
  --username "optional" `
  --password $env:AZ_DEVOPS_PAT --store-password-in-clear-text `

  # ie nuget install mage-runner `
  #   -Source octopus `
  #   -OutputDirectory mage `
  #   -Version $env:MAGE_RUNNER_VERSION
  # dotnet tool install mage-runner `
  # --add-source octopus `
  # --tool-path mage `
  # --version $env:MAGE_RUNNER_VERSION

  $env:PACKAGE_BASE_ADDRESS=$(curl -u "optional:$env:AZ_DEVOPS_PAT" -L https://pkgs.dev.azure.com/USXpress-Inc/CloudOps/_packaging/Octopus/nuget/v3/index.json | jq -r '.resources[] | select(.["@type"] | test("PackageBaseAddress/.*")) | .["@id”]’)

  mkdir -p mage && curl -u "optional:$env:AZ_DEVOPS_PAT" -Lo "mage/mage-runner.$env:MAGE_RUNNER_VERSION.nupkg" "$env:PACKAGE_BASE_ADDRESS/mage-runner/1.2.0/mage-runner.1.2.0.nupkg"

  Expand-Archive -Path "mage/mage-runner.$env:MAGE_RUNNER_VERSION.nupkg" -DestinationPath "mage"

  # Move-Item -Path ./mage/*/mage -Destination ./mage/
  chmod +x ./mage/mage

  $deployYamlsFound | ForEach-Object -Parallel {
    ins "./mage/mage octopus:octoPush $($_.FullName)" -ErrorOnFailure
  }
}
else {
  throw "::error::No Deploy files (.yaml|.yml) files found in .variant folder"
}
