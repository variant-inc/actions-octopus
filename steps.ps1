  $headers = @{
    'x-api-key'    = $env:LAZY_API_KEY
    'Content-Type' = 'application/json'
  }

if (Test-Path -Path $octoYamlPath -PathType Leaf)
{
  Write-Output "Gathering Space/Project from octopus.yaml"
  $octoDeploymentSteps = ce yq eval -j $octoYamlPath

  Write-Output $octoDeploymentSteps

  $octoProjectEndpoint = "https://$env:LAZY_API_URL/octopus/project?user=$env:GITHUB_ACTOR"

  Write-Output "Lazy API URL $octoProjectEndpoint"
  $Response = Invoke-RestMethod -Uri $octoProjectEndpoint `
    -Headers $headers -Method POST -Body $octoDeploymentSteps

  $Response | ConvertTo-Json
}
else
{
  Write-Output "Gathering Space/Project from workflow input"

  $Body = `
  @{"SpaceName"   = "$SPACE_NAME";
    "ProjectName" = "$PROJECT_NAME";
  }

  Write-Output "Octopus Project Request Body"
  Write-Output $Body

  $octoProjectEndpoint = "https://$env:LAZY_API_URL/octopus/project?user=$env:GITHUB_ACTOR"

  Write-Output "Lazy API URL $octoProjectEndpoint"

  $Response = Invoke-RestMethod -Uri $octoProjectEndpoint `
    -Headers $headers -Method POST -Body ($Body | ConvertTo-Json)

  $Response | ConvertTo-Json
}

Write-Output "Octopus add manual intervention step"

$octoManInterventionEndpoint = "https://$env:LAZY_API_URL/octopus/spaces/$SPACE_NAME/projects/$PROJECT_NAME/add-manual-intervention-step?user=$env:GITHUB_ACTOR"

Write-Output "Lazy API Manual intervention endpoint URL $octoManInterventionEndpoint"

$Body = `
@{"Environments"   = ["production"];
  "ResponsibleTeamIds" = "teams-administrators";
}
Write-Output "Manual intervention request Body"
Write-Output $Body
$Response = Invoke-RestMethod -Uri $octoManInterventionEndpoint `
-Headers $headers -Method PATCH -Body ($Body | ConvertTo-Json)
$Response | ConvertTo-Json