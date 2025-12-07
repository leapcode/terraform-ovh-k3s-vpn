variable "k3s_cluster_name" {
  type        = string
  default     = "k3s-leap"
  description = "Name of the cluster"
}

variable "k3s_network_name" {
  type        = string
  default     = "k3s-leap"
  description = "Name of the network to be created for the k3s cluster"

}

variable "ovh_service_name" {
  type        = string
  description = "The id of the ovh public cloud project"
}

variable "ovh_region" {
  type    = string
}

variable "k3s_leader_count" {
  type        = number
  default     = 1
  description = "Number of leader nodes. Must be an odd number. Please keep in mind that there might be quotas on the number of instances you can create."

  # validation {
  #   condition     = var.k3s_leader_count % 2 == 1
  #   error_message = "Invalid value for k3s_leader_count. It must be an odd number (e.g. 1, 3, 5)."
  # }
  # TODO: change as soon as multi-leader is implemented
  validation {
    condition     = var.k3s_leader_count == 1
    error_message = "Invalid value for k3s_leader_count. Right now it must be 1 until multi-leader support is implemented."
  }
}

# TODO: pin to v1.33
# variable "k3s_version" {
#   type        = string
#   default     = "v1.32.5+k3s1"
#   description = "Version of K3s to download from Github"
# }

variable "k3s_controller_server_type" {
  type        = string
  default     = "b2-7"
  description = "OVH server flavor name for controller nodes. Choose one from https://www.ovhcloud.com/de/public-cloud/prices/#552. Default is b2-7."
}

variable "k3s_worker_nodes" {
  description = "List of k3s worker group definitions. Please keep in mind that there might be quotas on the number of instances you can create."
  type = list(object({
    name        = string
    count       = number
    server_type = string
    image_name  = optional(string)
  }))
}

variable "k3s_base_os" {
  type        = string
  default     = "Debian 13"
  description = "OVH image name for operating system. Default is Debian 13."
}

variable "gateway_mode_enabled" {
  description = "Set to true to enable gateway, false to disable."
  type        = bool
  default     = false
}

variable "admin_ssh_key" {
  description = "Public SSH key to connect with all nodes"
  type = object({
    name = string
    public_key = string
  })
}

variable "additional_ssh_keys" {
  description = "List of additional SSH public keys to add to authorized_keys on all nodes."
  type        = list(string)
  default     = []
}
