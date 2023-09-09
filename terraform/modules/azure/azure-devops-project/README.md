## Description

Creates an Azure DevOps Project with optional service endpoints (AzureRM or GitHub).

## Inputs

| Name             | Description                              | Type           | Default | Required |
|------------------|------------------------------------------|----------------|---------|:--------:|
| project_name     | The name of the Azure DevOps project     | `string`       | n/a     |   yes    |
| github_endpoints | A list of GitHub endpoints to be created | `list(string)` | `[]`    |    no    |
| github_pat       | The GitHub Personal Access Token         | `string`       | `null`  |    no    |
| arm_endpoints    | A list of ARM endpoints to be created    | `list(object)` | `[]`    |    no    |

## Outputs

| Name              | Description                          |
|-------------------|--------------------------------------|
| id                | The ID of the Azure DevOps project   |
| name              | The name of the Azure DevOps project |
| service_endpoints | The IDs of the service endpoints     |
