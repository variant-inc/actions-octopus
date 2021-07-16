$IsPresent = $false

$TerraformDir = "$env:GITHUB_WORKSPACE/$env:TERRAFORM_DIR_PATH"

if (Test-Path -Path "$TerraformDir/*.tf")
{
  $IsPresent = $true
  Invoke-EpsTemplate -Path $PSScriptRoot/templates/terraform_dynamodb.eps `
  | Out-File -FilePath $TerraformDir/iaac_replicator_dynamodb.tf
}

$HelmDir = "$env:GITHUB_WORKSPACE/$env:CHARTS_DIR_PATH"

if (Test-Path -Path "$HelmDir/Chart.yaml" -and ! $IsPresent)
{
  $IsPresent = $true
  Invoke-EpsTemplate -Path $PSScriptRoot/templates/helm_configmap.eps `
  | Out-File -FilePath $HelmDir/templates/iaac_replicator_configmap.yaml
}

if (! $IsPresent)
{
  Write-Error "Chart.yaml file is missing at [$HelmDir]."
}
