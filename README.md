# Actions Setup
<!-- markdownlint-disable line-length -->
<!-- action-docs-description -->

<!-- action-docs-description -->

## Usage with octopus.yaml

### Octopus.yaml

Include a file in the .octopus/workflow directory called octopus.yaml.
Here you define your Octopus Project and deployment steps.
Everything in the Process object is taken from the octopus api.

```yaml
---
# Name of the space where the project belongs to
# Currently the available ones are
# Required
# `Engineering` `Mobile` `DataScience` `DriverProduct`
SpaceName: DevOps

# Name of the octopus project.
# If project isn't found, then one will be created in the provided space
# Required
ProjectName: iaac

Process:
    # Dummy name which will have no effect on the UI.
    # It is preferred to keep the Action Name and the Process name as the same
    # New processes can be added on a new line with -Name: key
  - Name: TF Apply
    ## Condition determines when the process can be run
    # Can be the following
    # `Success` `Always` `Variable` `Failure`
    # Default: Success
    Condition: Success

    Properties:
      # This step is run if the provided variable is `true`.
      # Condition should be `Variable` for this
      # Default: ""
      Octopus.Step.ConditionVariableExpression: "#{AWS_ACCESS_KEY_ID}"

    ## This determines whether the process has be run as parallel or sequential
    # Can have the following values
    # `StartAfterPrevious` `StartWithPrevious`
    # Default: StartAfterPrevious
    StartTrigger: StartAfterPrevious

    # Even though it is an array, use only 1 action
    # Multiple actions are for deployment targets which we aren't using
    Actions:

        # Name of the Deployment Process
        # This is the name that will be visible in the UI
        # Required
      - Name: TF Apply

        # Is the step disabled?
        # can be
        # `true` `false`
        # Default: false
        IsDisabled: false

        ## Only one of Environments, ExcludedEnvironments can be provided
        # List of Environments where the process is run
        # If list is empty, then process will be run in all environments
        # or determined by ExcludedEnvironments
        Environments: []
        # List of Environments where the process is excluded
        # If list is empty, then process will be run in all environments
        # or determined by Environments
        ExcludedEnvironments: []

        # List of Channels where the process is run
        # If list is empty, then process will be run in all channels
        Channels: []

        Properties:
          # Use Package if you need to run a script included in a deploy package.
          # Default: Package
          Octopus.Action.Script.ScriptSource: Package

          # Name of the script file relative to the deployment folder root
          # If structure of the repository is similar to below
          #     root
          #     |
          #     |__scripts/
          #     |__terraform/
          #     |__make
          #     |__Dockerfile
          # and the deployment folder is root
          # and the file is in scripts folder as deploy.sh,
          # then provide `scripts/deploy.sh`
          #
          # If structure of the repository is similar to below,
          #     root
          #     |
          #     |__deploy/
          #     |__src/
          #     |__make
          #     |__Dockerfile
          # and the deployment folder is,
          # and the file is in deploy folder as deploy.sh,
          # then provide `deploy.sh`
          # Required
          Octopus.Action.Script.ScriptFileName: deploy.ps1

          # Provide only 1 Name. This name will be the folder where the package for the release will be extracted
          Packages:
            - Name: deploy
          # Used when Parameters when `Octopus.Action.Script.ScriptSource` is `Package`

          # Parameters to be passed to the script above
          Octopus.Action.Script.ScriptParameters: "hello world"

          # Files where variables that need to be substituted by Octopus using
          # Structured configuration variables
          # Supports: `json` `yml` `yaml` `xml` `java properties`
          # https://octopus.com/docs/deployment-process/configuration-features/structured-configuration-variables-feature
          Octopus.Action.Package.JsonConfigurationVariablesTargets: terraform/environment/octo.tfvars.json

          # Files where variables that need to be substituted by Octopus using
          # simple variable substitution
          # Supports: `any plain text file`
          # https://octopus.com/docs/projects/variables/variable-substitutions
          Octopus.Action.SubstituteInFiles.TargetFiles: terraform/environment/octo.tfconfig

          # Use below if the script in your deployment is Inline
          # Inline Script Source needs a Script Body where you'll enter your script
          Octopus.Action.Script.ScriptSource: Inline

          # The syntax of the script that you are trying to execute
          # Can be `Powershell` `Bash` `CSharp` `FSharp` `Python`
          # Default: `Bash`
          Octopus.Action.Script.Syntax: Bash
          # Required when Parameters when `Octopus.Action.Script.ScriptSource` is `Inline`

          # Contains the script that will be executed
          Octopus.Action.Script.ScriptBody: |
            echo "Hello World"
          # Required when Parameters when `Octopus.Action.Script.ScriptSource` is `Inline`
```

For more [examples](file:/../examples/.octopus), see examples/.octopus/workflow directory

#### Octopus.yaml Schema

- SpaceName (String) The name of the Space associated with the Project.
- ProjectName (String) The name of the Project associated with this deployment process.
- Process (List) See below for nested schema for Process. Each process is a deployment step.

Nested Schema for Process

- Name (String) Name of the Process
- PackageRequirement (String) Whether to run this step before or after package acquisition (if possible). (LetOctopusDecide, AfterPackageAcquisition, BeforePackageAcquisition)
- Condition (String) When to run the step, (Success, Always, Variable, Failure)
- StartTrigger (String) Whether to run this step after the previous step (StartAfterPrevious) or at the same time as the previous step (StartWithPrevious)
- Properties (Map of String) Extra options

  Example keys
  - Octopus.Step.ConditionVariableExpression
- Actions (List) See below for nested schema for Actions

Nested Schema for Actions

- Name (String) Name of the Action, should be the same as Process Name
- ActionType (String) The type of action. (Octopus.Script, Octopus.TentaclePackage...)
- Notes (String) Extra info on you deployment step
- IsDisabled (Boolean) Indicates the disabled status of this deployment action.
- IsRequired (Boolean) Indicates the required status of this deployment action.
- CanBeUsedForProjectVersioning (Boolean)
- Channels (List of String) The channels associated with this deployment action
- Condition (String) The condition associated with this deployment action.
- Environments (List of String) The environments within which this deployment action will run.
- ExcludedEnvironments (List of String) The environments that this step will be skipped in
- Packages (List) The package associated with this action. (see below for nested schema)
- Properties (Map of String) The properties associated with this deployment action

  Example keys
  - Octopus.Action.RunOnServer (Boolean)
  - Octopus.Action.EnabledFeatures (String)
    - ex. "Octopus.Features.JsonConfigurationVariables,Octopus.Features.SubstituteInFiles"
  - Octopus.Action.Script.ScriptSource (String)
  - Octopus.Action.Script.ScriptFileName (String)
  - Octopus.Action.Package.PackageId (String)
  - Octopus.Action.Package.DownloadOnTentacle (Boolean)
  - Octopus.Action.Script.ScriptParameters (String)
  - Octopus.Action.Package.JsonConfigurationVariablesTargets (String) PAth of files to substitute variables
  - Octopus.Action.SubstituteInFiles.TargetFiles (String) Path of files to substitute

Nested Schema for Packages

- Name (String) Name of the Package to include in this step

### <github_workflow>.yaml

Include action-octopus input variables in your actions YAMLs file.

```yaml

    - name: Lazy Action Octopus
      uses: variant-inc/actions-octopus@v1
      with:
        default_branch: ${{ env.MASTER_BRANCH }}
        deploy_scripts_path: deploy
        version: ${{ steps.lazy-setup.outputs.image_version }}

```

___

## Usage Without Octopus.yaml

To run without using Octopus configuration as code, include space_name and project_name inputs within your github workflow.

```yaml

    - name: Lazy Action Octopus
      uses: variant-inc/actions-octopus@v1
      with:
        default_branch: ${{ env.MASTER_BRANCH }}
        deploy_scripts_path: deploy
        project_name: ${{ env.PROJECT_NAME }}
        version: ${{ steps.lazy-setup.outputs.image_version }}
        space_name: ${{ env.OCTOPUS_SPACE_NAME }}
```

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
