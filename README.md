# Actions Setup
<!-- action-docs-description -->
## Description

** Input required if .octopus/workflow/octopus.yaml does not exists.
See [Usage with octopus.yaml](#with-octopusyaml) section.
*** Either `charts_dir_path` or `terraform_dir_path` is required.

## Usage

### Without Octopus.yaml

To run without using Octopus configuration as code,
include space_name and project_name inputs within your github workflow.

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

v2 has the ability to let our internal `replicator`
application to know whether a specific repository has been deployed in an environment

1. Change uses to `variant-inc/actions-octopus@v2`
2. Add either `charts_dir_path` or `terraform_dir_path` variable
3. If the project has dependencies used by other project,
  then set `is_infrastructure` to `true`.
<!-- action-docs-description -->

<!-- markdownlint-disable line-length -->
<!-- action-docs-inputs -->
## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| default_branch | Default/Main Branch Name | `false` | master |
| deploy_scripts_path | Path to the deploy scripts which is packaged and pushed to Octopus. This folder will contains the necessary scripts/helm charts/other misc to run the deployments  | `false` | . |
| version | Semantic Version that is used for determining the package and release version  | `true` |  |
| space_name | Name of the Space in Octopus. Usually, this will be Engineering, Mobile, DevOps, etc.  | `false` |  |
| project_name | Name of the project name in Octopus | `false` |  |
| feature_channel_branches | Regex of the branches that has to deployed to dev.  | `false` | .* |
<!-- action-docs-inputs -->
<!-- markdownlint-enable line-length -->

<!-- action-docs-outputs -->

<!-- action-docs-outputs -->

<!-- action-docs-runs -->
## Runs

This action is a `composite` action.
<!-- action-docs-runs -->
