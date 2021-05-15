# terraform-deployments

-----------

These are larger Terraform deployments that build a specific infrastructure:
  - `azure-infrastructure`: Azure infrastructure for the data pipeline and project
  - `workspace-bootstrap`: Databricks workspace bootstrap

## Usage

To run a deployment: `./run-deployment.sh [subfolder]`
```
./run-deployment.sh azure-infrastructure
```

To destroy a deployment: `./destroy-deployment.sh [subfolder]`
```
./destroy-deployment.sh azure-infrastructure
```
