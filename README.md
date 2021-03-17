# Octopus GitHub Action

This action pushes the files to Octopus for deployments

```yaml
default_branch: master
deploy_scripts_path: deploy
project_name: lazy-api
version: 0.1.0
space_name: DevOps
feature_channel_branches: develop
```

## Input variables

| Parameter                | Default  | Description                                                                                                                                                                  | Required | Example  |
| ------------------------ | -------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------- |
| default_branch           | `master` | Directory of the solution file                                                                                                                                               | false    | master   |
| deploy_scripts_path      | `.`      | Directory of the files/folders that need to be packaged and sent to octopus                                                                                                  | false    | deploy   |
| project_name             |          | Name of the Octopus project                                                                                                                                                  | true     | lazy-api |
| version                  |          | Release and Package Version for Octopus Release/Package                                                                                                                      | true     | 0.1.1    |
| space_name               |          | Name of the space the Octopus project belongs to                                                                                                                             | DevOps   |
| feature_channel_branches | `.*`     | Which branches should be deployed to feature channel. Refer <https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions> | false    | develop  |

## Usage

```yaml

    - name: Lazy Action Octopus
      uses: variant-inc/actions-octopus@v1
      with:
        default_branch: ${{ env.MASTER_BRANCH }}
        deploy_scripts_path: deploy
        project_name: ${{ env.PROJECT_NAME }}
        version: ${{ steps.lazy-setup.outputs.image-version }}
        space_name: ${{ env.OCTOPUS_SPACE_NAME }}

```
