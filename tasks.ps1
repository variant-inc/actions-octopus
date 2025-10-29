$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap {
  Write-Error $_.InvocationInfo.ScriptName -ErrorAction Continue
  $line = "$($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"
  Write-Error $line -ErrorAction Continue
  Write-Error $_
}

# Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
# Install-Module Native
# Import-Module Native

$DeployYamlDir = [System.IO.Path]::GetFullPath($env:DEPLOY_YAML_DIR)
$MageDir = [System.IO.Path]::GetFullPath($env:MAGE_DIR_PATH)

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

  $deployYamlsFound | ForEach-Object -Parallel {
    & "$using:MageDir/mage" octopus:octoPush $($_.FullName)
    if ($LASTEXITCODE)
    {
      throw "Exception Occured"
    }
  }
}
else {
  throw "::error::No Deploy files (.yaml|.yml) files found in $env:DEPLOY_YAML_DIR"
}
