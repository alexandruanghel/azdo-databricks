variable "name" {
  type        = string
  description = "The display name for the App Registration."
}

variable "owners" {
  type        = list(string)
  description = "(Optional) A list of Azure AD Object IDs that will be granted ownership of the application."
  default     = []
}

variable "api_permissions" {
  type        = list(string)
  description = "(Optional) A list of API Permissions that should be assigned to this App (with admin consent)."
  default     = []
}

variable "secret" {
  type        = string
  description = "(Optional) The Password / Secret for this Application. One will be generated if not provided."
  default     = null
  sensitive   = true
}

variable "secret_expiration" {
  type        = string
  description = "(Optional) A relative duration for which the password is valid. Default is 8760h (1 year)."
  default     = "8760h"
}
