$IsPresent = $false

$TerraformDir = "$env:GITHUB_WORKSPACE/$env:TERRAFORM_DIR_PATH"

if (Test-Path -Path "$TerraformDir/*.tf")
{
  Write-Information "Terraform found at $TerraformDir"
  $IsPresent = $true
  Invoke-EpsTemplate -Path $PSScriptRoot/templates/terraform_dynamodb.eps `
  | Out-File -FilePath $TerraformDir/iaac_replicator_dynamodb.tf
}

$HelmDir = "$env:GITHUB_WORKSPACE/$env:CHARTS_DIR_PATH"

if ((Test-Path -Path "$HelmDir/Chart.yaml") -and (! $IsPresent))
{
  Write-Information "Helm Chart found at $HelmDir"
  $IsPresent = $true
  Invoke-EpsTemplate -Path $PSScriptRoot/templates/helm_configmap.eps `
  | Out-File -FilePath $HelmDir/templates/iaac_replicator_configmap.yaml
}

if (! $IsPresent)
{
  Write-Error "Either Terraform ($TerraformDir) or Helm Chart ($HelmDir) dir path has to be valid"
}
