# Qwiklabs Mandatory Values

/*variable "gcp_project_id" {
  type = string
}

variable "gcp_region" {
  type = string
}

variable "gcp_zone" {
  type = string
} 
*/

variable "vm_prefix" {
  type        = string
  description = "the common VM names prefix"
  default     = "vm"
}

variable "region" {
  type        = string
  description = "the region where the resources live"
  default     = "us-central1"
}

variable "create_www_instance" {
  type        = bool
  description = "Whether the www VM should be created."
  default     = false
}

### loops
variable "my_vms" {
  type        = list(string)
  description = "My VMs."
}

