## Description

Creates an Azure DevOps Pipeline (hosted on GitHub) with optional variables.

## Inputs

| Name               | Description                                                            | Type          | Default  | Required |
|--------------------|------------------------------------------------------------------------|---------------|----------|:--------:|
| pipeline_name      | The name of the Azure DevOps pipeline                                  | `string`      | n/a      |   yes    |
| pipeline_path      | The path in the GitHub repo to the pipelines YAML file                 | `string`      | n/a      |   yes    |
| project_id         | The ID of the Azure DevOps project                                     | `string`      | n/a      |   yes    |
| github_endpoint_id | The ID of the GitHub service endpoint                                  | `string`      | n/a      |   yes    |
| github_repo_url    | The URL used by the GitHub service endpoint and pipeline               | `string`      | n/a      |   yes    |
| github_branch      | Branch name for which the pipeline will be configured                  | `string`      | `master` |    no    |
| pipeline_variables | A map of variables names and values that should be set to the pipeline | `map(string)` | `{}`     |    no    |

## Outputs

| Name     | Description                                                            |
|----------|------------------------------------------------------------------------|
| id       | The ID of the Azure DevOps pipeline                                    |
| name     | The name of the Azure DevOps pipeline                                  |
| name     | Full Git path to the yaml file of the Azure DevOps pipeline definition |
| revision | The revision of the Azure DevOps pipeline                              |
