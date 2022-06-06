# Octopus GitHub Action

## Input variables

| Parameter     | Default  | Description                   | Required| Example|
| --------------| ---------| ------------------------------| --------| -------|
| default_branch| `master` | Directory of the solution file| false   | master |
___

## Usage

Please reference
[DX Workflow](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs)
documentation as actions-octopus v3 should only be used in tandem with DX Workflow.
DX Workflow defines and deploys both infrastructure and applications.

1. Create a deployment spec in `.variant/deploy`. Reference the
   [DX Workflow Documentation](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Getting-Started/Tutorials/)
   and these [examples](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/dx-requirements/#full-end-end-example-repositories)
   for more information.

2. Add a build step to your GitHub actions workflow yaml. More examples
   [here](https://backstage.apps.ops-drivevariant.com/docs/default/Component/dx-docs/Getting-Started/Github/Github-Actions/).

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
