param (
    [string]$SpaceName,
    [string]$ProjectName
)
# This will check for a project in the space and if it doesn't exist create it
# by cloning the default project and putting it in the Default Project Group.
# If a project exists in the space it will ensure it is enabled.


if (-not $SpaceName) { throw "Space Name not provided." }
if (-not $ProjectName) { throw "Project Name not provided." }

try {
    # Check if the project already exists
    $project = octopus project list --space $space --outputFormat json | ConvertFrom-Json |
    Where-Object { $_.Name -eq $ProjectName }

    if (-not $project) {
        Write-Output "Creating project '$ProjectName'..."

        # Clone the default project into the new one
        ce octopus project clone --space $space `
            --source "default" `
            --name $ProjectName `
            --group "Default Project Group" `
            --description "Cloned from Default Project" `
            --no-prompt --output-format json

        Write-Output "Project '$ProjectName' has been successfully created."
        # Output project details
        Write-Output $project
    }
    else {
        Write-Output "Project '$ProjectName' already exists in space '$SpaceName'."
    }

    if (-not ($env:GITHUB_REF -imatch "renovate" -or $env:GITHUB_REF -imatch "dependabot")) {
        octopus project enable $ProjectName --space $space --no-prompt
    }
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
