$text = [string]::Format(((Get-Content $env:ACTION_PATH/octopus_configmap.yaml) -join "`n"),
"$env:SPACE_NAME",
"$env:PROJECT_NAME",
"${env:GITHUB_REPOSITORY}",
"$env:GITHUB_ACTOR",
"${env:VERSION}",
"${env:IMAGE_NAME}"
)
$repoName =  basename $(git remote get-url origin) .git
Set-Content -Path $env:GITHUB_WORKSPACE/${env:DEPLOY_SCRIPTS_PATH}/${env:CHARTS_DIR_PATH}/$repoName/templates/octopus_configmap.yaml -Value $text