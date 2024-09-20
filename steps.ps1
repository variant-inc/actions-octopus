Write-Output "=== Gathering Space and Project Information ==="

# Retrieve environment variables for Space and Project names
$SPACE_NAME = $env:SPACE_NAME
$PROJECT_NAME = $env:PROJECT_NAME

Write-Output "Space Name: $SPACE_NAME"
Write-Output "Project Name: $PROJECT_NAME"

# Check if Space Name is provided
if (($null -eq $SPACE_NAME) -or ("" -eq $SPACE_NAME)) {
    throw "Error: Space Name not provided. Please set the SPACE_NAME environment variable."
}

# Check if Project Name is provided
if (($null -eq $PROJECT_NAME) -or ("" -eq $PROJECT_NAME)) {
    throw "Error: Project Name not provided. Please set the PROJECT_NAME environment variable."
}

# Check if project.ps1 exists
$projectScriptPath = "./project.ps1"
Write-Output "Checking if project script exists at path: $projectScriptPath"
if (-Not (Test-Path $projectScriptPath)) {
    throw "Error: Script project.ps1 not found at path: $projectScriptPath. Ensure the script is available."
}

# Preparing to call project.ps1 with parameters
Write-Output "=== Preparing to Call Project Script ==="
Write-Output "Calling project.ps1 with parameters:"
Write-Output "  SpaceName: $SPACE_NAME"
Write-Output "  ProjectName: $PROJECT_NAME"

# Define parameters to pass to project.ps1
$scriptParams = @{
    "SpaceName"   = $SPACE_NAME
    "ProjectName" = $PROJECT_NAME
}

# Call the project.ps1 script and capture the output
Write-Output "Executing project.ps1..."
$projectOutput = & $projectScriptPath @scriptParams

# Check if the script executed successfully
if ($LASTEXITCODE -ne 0) {
    throw "Error: project.ps1 script execution failed. Check the script for errors."
}

# Output the result from project.ps1
Write-Output "=== Project Script Output ==="
Write-Output $projectOutput
Write-Output "=== End of Project Script Execution ==="
