param (
    [string]$SpaceName,
    [string]$ProjectName
)

# Function to run Octopus CLI commands and handle errors
function Invoke-OctopusCliCommand {
    param (
        [string[]]$Command
    )
    $result = & $Command 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Octopus CLI command failed: $result"
        throw "Octopus CLI command failed: $result"
    }
    return $result
}

# Function to get the space ID from the space name
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

# Function to get or create a project
function Get-OrCreateProject {
    param (
        [string]$SpaceId,
        [string]$ProjectName
    )

    $command = @("octopus", "project", "list", "--space", $SpaceId, "--outputFormat", "json")
    $projectsOutput = Invoke-OctopusCliCommand -Command $command
    $projects = $projectsOutput | ConvertFrom-Json
    $project = $projects | Where-Object { $_.Name -eq $ProjectName }

    if (-not $project) {
        Write-Output "Project not found, creating project"
        $defaultProjectGroupId = Get-DefaultProjectGroupId -SpaceId $SpaceId
        $releaseLifecycleId = Get-ReleaseLifecycleId -SpaceId $SpaceId
        $command = @(
            "octopus", "project", "create",
            "--name", $ProjectName,
            "--space", $SpaceId,
            "--projectGroup", $defaultProjectGroupId,
            "--lifecycle", $releaseLifecycleId,
            "--outputFormat", "json"
        )
        $projectOutput = Invoke-OctopusCliCommand -Command $command
        $project = $projectOutput | ConvertFrom-Json
    }

    return $project
}

# Function to get default project group ID
function Get-DefaultProjectGroupId {
    param (
        [string]$SpaceId
    )
    $command = @("octopus", "project-group", "list", "--space", $SpaceId, "--outputFormat", "json")
    $groupsOutput = Invoke-OctopusCliCommand -Command $command
    $groups = $groupsOutput | ConvertFrom-Json
    $defaultGroup = $groups | Where-Object { $_.Name -eq "Default Project Group" }
    return $defaultGroup.Id
}

# Function to get release lifecycle ID
function Get-ReleaseLifecycleId {
    param (
        [string]$SpaceId
    )
    $command = @("octopus", "lifecycle", "list", "--space", $SpaceId, "--outputFormat", "json")
    $lifecyclesOutput = Invoke-OctopusCliCommand -Command $command
    $lifecycles = $lifecyclesOutput | ConvertFrom-Json
    $releaseLifecycle = $lifecycles | Where-Object { $_.Name -eq "release" }
    return $releaseLifecycle.Id
}

# Function to get built-in feed ID
function Get-BuiltInFeedId {
    param (
        [string]$SpaceId
    )
    $command = @("octopus", "feed", "list", "--space", $SpaceId, "--outputFormat", "json")
    $feedsOutput = Invoke-OctopusCliCommand -Command $command
    $feeds = $feedsOutput | ConvertFrom-Json
    $builtInFeed = $feeds | Where-Object { $_.FeedType -eq "BuiltIn" }
    return $builtInFeed.Id
}