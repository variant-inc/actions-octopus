# Octopus GitHub Action

## Input variables

| Parameter     | Default  | Description                   | Required| Example|
| --------------| ---------| ------------------------------| --------| -------|
| default_branch| `master` | Directory of the solution file| false   | master |
___

## Usage

Please reference
[DX Workflow](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/2407563355/DX+Workflow+Documentation)
documentation as actions-octopus v3 should only be used in tandem with DX Workflow.
DX Workflow defines and deploys both infrastructure and applications.

1. Create a deployment spec in `.variant/deploy`. Reference the
   [DX Workflow Documentation](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/2407563355/DX+Workflow+Documentation)
   and these [examples](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/2429222950/DX+-+Full+End+to+End+Examples)
   for more information.

2. Add a build step to your GitHub actions workflow yaml. More examples
   [here](https://drivevariant.atlassian.net/wiki/spaces/CLOUD/pages/2407563355/DX+Workflow+Documentation#Examples).

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
