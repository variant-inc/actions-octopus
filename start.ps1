$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"
$WarningPreference = "SilentlyContinue"

Trap
{
  Write-Error $_.InvocationInfo.ScriptName -ErrorAction Continue
  $line = "$($_.InvocationInfo.ScriptLineNumber): $($_.InvocationInfo.Line)"
  Write-Error $line -ErrorAction Continue
  Write-Error $_
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

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Scope = 'Function')]
$octoYamlPath = [System.IO.Path]::GetFullPath((Join-Path ${env:GITHUB_WORKSPACE} ".octopus/workflow/octopus.yaml"))

# Preparing to call project.ps1 with parameters
Write-Output "=== Calling project.ps1 with parameters: ==="
$scriptParams = @{
    "SpaceName"   = $env:SPACE_NAME
    "ProjectName" = $env:PROJECT_NAME
}
$projectScriptPath = "$env:ACTION_PATH/project.ps1"
$projectOutput = & $projectScriptPath @scriptParams

if ($LASTEXITCODE -ne 0) {
    throw "Error: project.ps1 script execution failed."
}
Write-Output $projectOutput
Write-Output "=== End of Project Script Execution ==="

& $env:ACTION_PATH/release.ps1
Write-Output "Octopus Release Complete"
