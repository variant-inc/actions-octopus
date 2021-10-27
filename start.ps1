[CmdLetBinding()]
[Diagnostics.CodeAnalysis.SuppressMessage("PSAvoidGlobalVars", '')]
Param()

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

if (Test-Path -Path $octoYamlPath -PathType Leaf)
{
  Write-Output "Gathering Space/Project from octopus.yaml"
  $octoWorkflow = $(ce yq eval -j $octoYamlPath | ConvertFrom-Json)

  Write-Output $octoWorkflow
  $global:SPACE_NAME = $octoWorkflow.SpaceName
  $global:PROJECT_NAME = $octoWorkflow.ProjectName
}
else
{
  Write-Output "Gathering Space/Project from workflow input"

  $global:SPACE_NAME = $env:SPACE_NAME
  $global:PROJECT_NAME = $env:PROJECT_NAME
}

if ([string]::IsNullOrEmpty($SPACE_NAME))
{
  throw "Space Name not provided"
}

if ([string]::IsNullOrEmpty($PROJECT_NAME))
{
  throw "Project Name not provided"
}

Write-Output "$env:ACTION_PATH/replicator.ps1"
. $env:ACTION_PATH/replicator/replicator.ps1
Write-Output "Set Configmap values Complete"

& $env:ACTION_PATH/steps.ps1
Write-Output "Octopus Project Configuration Complete"

& $env:ACTION_PATH/release.ps1
Write-Output "Octopus Release Complete"
