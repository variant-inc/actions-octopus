# Octopus GitHub Action

<!-- markdownlint-disable line-length -->
<!-- action-docs-description -->
## Description

Github Action to create release in Octopus.

## Usage

Please reference
[DX Workflow](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs)
documentation as actions-octopus v3 should only be used in tandem with DX Workflow.
DX Workflow defines and deploys both infrastructure and applications.

1. Create a deployment spec in `.variant/deploy`. Reference the
  [DX Workflow Documentation](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Getting-Started/Tutorials/)
  and these [examples](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/dx-requirements/#more-examples)
  for more information.

2. Add a build step to your GitHub actions workflow yaml. More examples
  [here](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Getting-Started/Github/Github-Actions/#examples-of-github-actions-that-the-dx-workflow-supports).

```yaml
- name: Lazy Action Octopus
  uses: variant-inc/actions-octopus@v3
```

## Migrating to v3

v3 runs CI using cake. Currently only repositories that do not deploy
infrastructure can migrate to v3.

1. Change uses new action version v3: `variant-inc/actions-octopus@v3`
2. Add a Variant Deploy Yaml File following the usage above.
  Note that only certain versions of charts in lazy-helm-charts are supported
  and may require you to update and fix breaking changes with
  the helm release.
<!-- action-docs-description -->

<!-- markdownlint-disable line-length -->
<!-- action-docs-inputs -->
## Inputs

| parameter | description | required | default |
| --- | --- | --- | --- |
| deploy_package_version | terraform-variant-apps package version | `false` | 1.1.1.663 |
| cake_runner_version | cake-runner package version Defaults to latest release version. Can be overriden by exact version or specifying range in NuGet notation. [NuGet notation](https://learn.microsoft.com/en-us/nuget/concepts/package-versioning)  | `false` |  |
<!-- action-docs-inputs -->
<!-- markdownlint-enable line-length -->

<!-- action-docs-outputs -->

<!-- action-docs-outputs -->

<!-- action-docs-runs -->
## Runs

This action is a `composite` action.
<!-- action-docs-runs -->
