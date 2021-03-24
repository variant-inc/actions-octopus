$octoYamlPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ".octopus/workflow/octopus.yaml"))
if (Test-Path -Path $octoYamlPath -PathType Leaf)
{
    $octoDeploymentSteps = yq eval -j $octoYamlPath
    Write-Output $octoDeploymentSteps
    $octoProjectEndpoint = "https://$env:LAZY_API_URL/octopus/project"
    $requestHeaders = New-Object System.Collections.Generic.Dictionary"[String,Int]"
    $requestHeaders.Add("x-api-key",$env:LAZY_API_KEY)
    $Response = Invoke-WebRequest -Uri $octoProjectEndpoint -Headers $requestHeaders -Method POST -Body $octoDeploymentSteps
    $Response.RawContent
}