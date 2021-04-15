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
  Write-Output "Gathering Space/Project from octopus.yaml"
  $octoDeploymentSteps = ce yq eval -j $octoYamlPath
  Write-Output $octoDeploymentSteps
  $octoProjectEndpoint = "https://$env:LAZY_API_URL/octopus/project"
  $requestHeaders = New-Object System.Collections.Generic.Dictionary"[String,Object]"
  $requestHeaders.Add("x-api-key",$env:LAZY_API_KEY)
  Write-Output "Lazy API URL $octoProjectEndpoint"
  $Response = Invoke-WebRequest -Uri $octoProjectEndpoint -Headers $requestHeaders -Method POST -Body $octoDeploymentSteps
  Write-Output $Response.RawContent
  if($Response.StatusCode -ne 200)
  {
      throw $Response
  }
} else {
  Write-Output "Gathering Space/Project from workflow input"
  $SPACE_NAME = $env:SPACE_NAME
  $PROJECT_NAME = $env:PROJECT_NAME
  if (($null -eq $SPACE_NAME) -or ("" -eq $SPACE_NAME))
  {
    throw "Space Name not provided"
  }

  if (($null -eq $PROJECT_NAME) -or ("" -eq $PROJECT_NAME))
  {
    throw "Project Name not provided"
  }

  $requestHeaders = New-Object System.Collections.Generic.Dictionary"[String,Object]"
  $requestHeaders.Add("x-api-key",$env:LAZY_API_KEY)

  $Body = `
  @{"SpaceName"="$SPACE_NAME";
    "ProjectName"="$PROJECT_NAME";
  }

  Write-Output "Octopus Project Request Body"
  Write-Output $Body
  
  $octoProjectEndpoint = "https://$env:LAZY_API_URL/octopus/project"
  Write-Output "Lazy API URL $octoProjectEndpoint"
  $Response = Invoke-WebRequest -Uri $octoProjectEndpoint `
    -Headers $requestHeaders `
    -Method POST -Body ($Body | ConvertTo-Json)

  Write-Output $Response.RawContent
  if($Response.StatusCode -ne 200)
  {
    throw $Response
  }
}