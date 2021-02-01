# Lazy Octopus GitHub Action

This action pushes the files to Octopus for deployments

default_branch:
  description: Default/Main Branch Name
  required: false
  default: master
deploy_scripts_path:
  description: >
    Path to the deploy scripts which is packaged
    and pushed to Octopus. This folder will contains the
    necessary scripts/helm charts/other misc to run the deployments
  required: false
  default: deploy
project_name:
  description: Name of the project name in Octopus
  required: true
version:
  description: >
    Semantic Version that is used for determining
    the package and release version
  required: true
space_name:
  description: >
    Name of the Space in Octopus. Usually, this will be Engineering,
    Mobile, DevOps, etc.
  required: true

## Input variables

| Parameter             | Default | Description                    | Required | Example |
| --------------------- | ------- | ------------------------------ | -------- | ------- |
| default_branch        | master  | Directory of the solution file | true     | master  |
| `dockerfile_dir_path` | `.`     | Directory of the dockerfile    | true     |
