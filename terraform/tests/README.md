# terraform-tests

-----------

Tests for the Terraform modules. Each subfolder corresponds directly to a `modules` subfolder.

This doesn't do automatic assertions yet, it simply makes sure the Terraform module can execute with all parameters.

## Usage

To run a test: `./run-test.sh [subfolder]`

```
./run-test.sh azure/databricks-workspace
```

To destroy a test: `./destroy-test.sh [subfolder]`

```
./destroy-test.sh azure/databricks-workspace
```
