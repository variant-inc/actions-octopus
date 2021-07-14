Invoke-EpsTemplate -Path $PSScriptRoot/replicator_configmap.eps `
| Out-File -FilePath $env:GITHUB_WORKSPACE/${env:CHARTS_DIR_PATH}/$repoName/templates/octopus_configmap.yaml