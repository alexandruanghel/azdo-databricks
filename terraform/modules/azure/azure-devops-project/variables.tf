variable "project_name" {
  type        = string
  description = "The name of the Azure DevOps project."
}

variable "github_endpoints" {
  type = list(string)
  description = "(Optional) A list of GitHub endpoints to be created."
  default     = []
}

variable "github_pat" {
  type        = string
  sensitive   = true
  description = "(Optional) The GitHub Personal Access Token. If not set, it will use the AZDO_GITHUB_SERVICE_CONNECTION_PAT environment variable."
  default     = null
}

variable "arm_endpoints" {
  type = list(object({
    name          = string
    client_id     = string
    client_secret = string
  })
  )
  sensitive   = true
  description = "(Optional) A list of ARM endpoints to be created. These must have a Name, a Service Principal Client ID and a Client Secret."
  default     = []
}
