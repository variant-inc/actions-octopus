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

$headers = @{
  'x-api-key'    = $env:LAZY_API_KEY
  'Content-Type' = 'application/json'
}

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
