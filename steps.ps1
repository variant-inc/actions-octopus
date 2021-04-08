$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap
{
  Write-Error $_ -ErrorAction Continue
  exit 1
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

$octoYamlPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ".octopus/workflow/octopus.yaml"))
if (Test-Path -Path $octoYamlPath -PathType Leaf)
  {
  $octoDeploymentSteps = ce yq eval -j $octoYamlPath
  Write-Output $octoDeploymentSteps
  $octoProjectEndpoint = "https://$env:LAZY_API_URL/octopus/project"
  $requestHeaders = New-Object System.Collections.Generic.Dictionary"[String,Int]"
  $requestHeaders.Add("x-api-key",$env:LAZY_API_KEY)
  $Response = Invoke-WebRequest -Uri $octoProjectEndpoint -Headers $requestHeaders -Method POST -Body $octoDeploymentSteps
  $Response.RawContent
  if($Response.StatusCode -ne 200)
  {
      throw $Response
  }
}