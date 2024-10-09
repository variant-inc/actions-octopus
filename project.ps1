param (
    [string]$SpaceName,
    [string]$ProjectName
)

function Invoke-OctopusCliCommand {
    param (
        [string[]]$Command
    )
    $result = & $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Octopus CLI command failed: $result"
    }
    return $result
}

function Get-SpaceIdFromName {
    param (
        [string]$SpaceName
    )
    $command = @("octopus", "space", "list", "--outputFormat", "json")
    $spacesOutput = Invoke-OctopusCliCommand -Command $command
    $spaces = $spacesOutput | ConvertFrom-Json
    $space = $spaces | Where-Object { $_.Name -eq $SpaceName }
    if (-not $space) {
        throw "Space with name '$SpaceName' not found."
    }
    return $space.Id
}

function Get-OrCreateProject {
    param (
        [string]$SpaceId,
        [string]$ProjectName
    )

    # List the projects in the specified space
    $command = @("octopus", "project", "list", "--space", $SpaceId, "--outputFormat", "json")
    $projectsOutput = Invoke-OctopusCliCommand -Command $command
    $projects = $projectsOutput | ConvertFrom-Json
    $project = $projects | Where-Object { $_.Name -eq $ProjectName }

    if (-not $project) {
        Write-Output "Project '$ProjectName' not found, creating a new one by cloning the default project."

        # Determine if default or "Default Project" exists
        $defaultProject = $projects | Where-Object { $_.Name -eq "default" -or $_.Name -eq "Default Project" }
        if (-not $defaultProject) {
            throw "Default project not found in space '$SpaceId'."
        }

        # Get the default project group and lifecycle IDs
        $defaultProjectGroupId = Get-DefaultProjectGroupId -SpaceId $SpaceId
        $releaseLifecycleId = Get-ReleaseLifecycleId -SpaceId $SpaceId

        # Clone the default project
        $command = @(
            "octopus", "project", "clone",
            "--space", $SpaceId,
            "--name", $ProjectName,
            "--sourceProjectId", $defaultProject.Id,
            "--projectGroup", $defaultProjectGroupId,
            "--lifecycle", $releaseLifecycleId,
            "--outputFormat", "json"
        )
        $projectOutput = Invoke-OctopusCliCommand -Command $command
        $project = $projectOutput | ConvertFrom-Json

        # Enable the newly created project
        Write-Output "Enabling the project '$ProjectName'."
        $command = @(
            "octopus", "project", "update",
            "--space", $SpaceId,
            "--id", $project.Id,
            "--isDisabled", "false",
            "--outputFormat", "json"
        )
        Invoke-OctopusCliCommand -Command $command
    }

    return $project
}

function Get-DefaultProjectGroupId {
    param (
        [string]$SpaceId
    )
    # Get the default project group ID
    $command = @("octopus", "project-group", "list", "--space", $SpaceId, "--outputFormat", "json")
    $groupsOutput = Invoke-OctopusCliCommand -Command $command
    $groups = $groupsOutput | ConvertFrom-Json
    $defaultGroup = $groups | Where-Object { $_.Name -eq "Default Project Group" }
    if (-not $defaultGroup) {
        throw "Default Project Group not found in space '$SpaceId'."
    }
    return $defaultGroup.Id
}

function Get-ReleaseLifecycleId {
    param (
        [string]$SpaceId
    )
    # Get the release lifecycle ID
    $command = @("octopus", "lifecycle", "list", "--space", $SpaceId, "--outputFormat", "json")
    $lifecyclesOutput = Invoke-OctopusCliCommand -Command $command
    $lifecycles = $lifecyclesOutput | ConvertFrom-Json
    $releaseLifecycle = $lifecycles | Where-Object { $_.Name -eq "release" }
    if (-not $releaseLifecycle) {
        throw "Release lifecycle not found in space '$SpaceId'."
    }
    return $releaseLifecycle.Id
}

# Main Execution
$SpaceId = Get-SpaceIdFromName -SpaceName $SpaceName
$Project = Get-OrCreateProject -SpaceId $SpaceId -ProjectName $ProjectName

Write-Output "Project '$ProjectName' in space '$SpaceName' has been successfully created or updated."
Write-Output $Project
