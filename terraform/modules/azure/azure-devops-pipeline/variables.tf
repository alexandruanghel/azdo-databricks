variable "pipeline_name" {
  type        = string
  description = "The name of the Azure DevOps pipeline."
}

variable "pipeline_path" {
  type        = string
  description = "The path in the GitHub repo to the pipelines YAML file."
}

variable "project_id" {
  type        = string
  description = "The ID of the Azure DevOps project."
}

variable "github_endpoint_id" {
  type        = string
  description = "The ID of the GitHub service endpoint."
}

variable "github_repo_url" {
  type        = string
  description = "The URL used by the GitHub service endpoint and pipeline."

  validation {
    condition     = length(regex("^https://[w.]*github.com/(?P<repo_id>[^/?#]+/[^/?#]+)", var.github_repo_url)) == 1
    error_message = "This must be a valid URL to a GitHub repository (https://github.com/<GitHub Org>/<Repo Name>)."
  }
}

variable "github_branch" {
  type        = string
  description = "(Optional) Branch name for which the pipeline will be configured. Default is master."
  default     = "master"
}

variable "pipeline_variables" {
  type        = map(string)
  description = "(Optional) A map of variables names and values that should be set to the pipeline."
  default     = {}
}
