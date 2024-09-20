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
    # Get the space by name
    $space = octopus space list --outputFormat json | ConvertFrom-Json |
             Where-Object { $_.Name -eq $SpaceName }

    if (-not $space) {
        throw "Space with name '$SpaceName' not found."
    }

    # Check if the project already exists
    $project = octopus project list --space $space.Id --outputFormat json | ConvertFrom-Json |
               Where-Object { $_.Name -eq $ProjectName }

    if (-not $project) {
        Write-Output "Creating project '$ProjectName'..."

        # Clone the default project into the new one
        octopus project clone --space $space.Id `
            --source "default" `
            --name $ProjectName `
            --group "Default Project Group" `
            --description "Cloned from Default Project" `
            --no-prompt --output-format json

        Write-Output "Project '$ProjectName' has been successfully created."
        # Output project details
        Write-Output $project
    } else {
        Write-Output "Project '$ProjectName' already exists in space '$SpaceName'."
    }

    octopus project enable  $ProjectName --space $space.Id --no-prompt --output-format json

} catch {
    Write-Error "An error occurred: $_"
    exit 1
}
