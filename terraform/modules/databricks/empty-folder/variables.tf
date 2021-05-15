variable "folder_path" {
  type        = string
  description = "The workspace path to the folder."
}

variable "permissions" {
  type = list(object({
    principal  = string
    type       = string
    permission = string
  })
  )
  description = "(Optional) An object of permissions to be assigned to the folder."
  default     = []
}
