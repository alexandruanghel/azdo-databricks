### Databricks Cluster Policies

# Deploy the Single Node Cluster Policy
# Give CAN_USE on the Single Node Cluster Policy to the Project group
module "databricks_policy_single_node" {
  source                = "../../modules/databricks/cluster-policy"
  policy_name           = "Single Node Cluster"
  CAN_USE               = [{principal = var.PROJECT_GROUP_NAME, type = "group"}]
  policy_overrides_file = var.DATABRICKS_CLUSTER_POLICY_LOCATION
  depends_on            = [module.project_group_sync]
}

# Terraform output
output "databricks_policies" {
  value = {
    single_node = {
      id          = module.databricks_policy_single_node.id
      details     = module.databricks_policy_single_node.details
      permissions = module.databricks_policy_single_node.permissions
    }
  }
}
