## Description

Creates a Databricks cluster policy with optional CAN_USE permissions.

The policy will be created by [merging](https://www.terraform.io/docs/language/functions/merge.html) the following
sources (in this order):

1. a default policy definition with optional variables
2. a policy json file
3. policy overrides as a Terraform object

## Inputs

| Name                            | Description                                                                 | Type           | Default              | Required |
|---------------------------------|-----------------------------------------------------------------------------|----------------|----------------------|:--------:|
| policy_name                     | Cluster policy name                                                         | `string`       | n/a                  |   yes    |
| CAN_USE                         | Objects of principals that should have CAN_USE permission on the policy     | `list(object)` | `[]`                 |    no    |
| default_spark_version_regex     | The default policy Spark version regex                                      | `string`       | `.*-scala2.12`       |    no    |
| default_autotermination_minutes | The default policy cluster autotermination in minutes                       | `number`       | `120`                |    no    |
| default_cluster_log_path        | The default policy location to deliver Spark driver, worker, and event logs | `string`       | `dbfs:/cluster-logs` |    no    |
| policy_overrides_file           | The path to a json file containing any cluster policy overrides             | `string`       | `null`               |    no    |
| policy_overrides_object         | Cluster policy overrides defined as object                                  | `object`       | `{}`                 |    no    |

## Outputs

| Name        | Description                                              |
|-------------|----------------------------------------------------------|
| id          | The ID of the cluster policy in the Databricks workspace |
| details     | Details about the cluster policy                         |
| permissions | List with the cluster policy permissions                 |
