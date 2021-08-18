# Octopus GitHub Action

## Input variables

| Parameter                | Default     | Description                                                                 | Required | Example          |
| ------------------------ | ----------- | --------------------------------------------------------------------------- | -------- | ---------------- |
| default_branch           | `master`    | Directory of the solution file                                              | false    | master           |
| deploy_scripts_path      | `.`         | Directory of the files/folders that need to be packaged and sent to octopus | false    | deploy           |
| project_name**           |             | Name of the Octopus project                                                 | false    | lazy-api         |
| space_name**             |             | Name of the space the Octopus project belongs to                            | false    | DevOps           |
| version                  |             | Release and Package Version for Octopus Release/Package                     | true     | 0.1.1            |
| feature_channel_branches | `.*`        | Which branches should be deployed to feature channel.                       | false    | develop          |
| charts_dir_path***       | `charts`    | Path to the charts directory directory                                      | false    | charts/variant   |
| terraform_dir_path***    | `terraform` | Path to the terraform directory directory                                   | false    | terraform/module |
| is_infrastructure        | `false`     | Is the repository only for creating infrastructure directory                | false    | charts           |

** Input required if .octopus/workflow/octopus.yaml does not exists. See [Usage with octopus.yaml](#usage-with-octopus.yaml) section.
*** Either `charts_dir_path` or `terraform_dir_path` is required.
___

### <github_workflow>.yaml

Include action-octopus input variables in your actions yamls file.

```yaml

- name: Lazy Action Octopus
  uses: variant-inc/actions-octopus@v2
  with:
    default_branch: ${{ env.MASTER_BRANCH }}
    deploy_scripts_path: deploy
    version: ${{ steps.lazy-setup.outputs.image_version }}
    charts_dir_path: charts
    is_infrastructure: false
```

___

## Usage

### Without Octopus.yaml

To run without using Octopus configuration as code, include space_name and project_name inputs within your github workflow.

```yaml
- name: Lazy Action Octopus
  uses: variant-inc/actions-octopus@v2
  with:
    default_branch: ${{ env.MASTER_BRANCH }}
    deploy_scripts_path: deploy
    project_name: ${{ env.PROJECT_NAME }}
    version: ${{ steps.lazy-setup.outputs.image_version }}
    space_name: ${{ env.OCTOPUS_SPACE_NAME }}
    charts_dir_path: helm/Variant.Api
    is_infrastructure: false
```

### With Octopus.yaml

[octopus-yaml.md](docs/octopus-yaml.md)

## Upgrade to v2

v2 has the ability to let our internal `replicator` application to know whether a specific repository has been deployed in an environment

1. Change uses to `variant-inc/actions-octopus@v2`
2. Add either `charts_dir_path` or `terraform_dir_path` variable
3. If the project has dependencies used by other project, then set `is_infrastructure` to `true`.
