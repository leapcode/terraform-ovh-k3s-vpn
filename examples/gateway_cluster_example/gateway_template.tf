# Template file for a single-node cluster to use as a gateway

# Use the existing k3s module from parent directory
module "k3s" {
  source       = "git::https://0xacab.org/leap/container-platform/terraform-ovh-k3s-vpn.git?ref=no-masters"
  
  # OVH Project details
  ovh_service_name = "<id_of_your_ovh_public_cloud_project>"
  ovh_region = "<ovh_public_cloud_datacenter_location>"

  # Single node configuration
  k3s_cluster_name = "k3s-gateway"

  # Network configuration
  k3s_network_name = "k3s-gateway-network"

  # Controller node server configuration
  k3s_controller_server_type = "b2-7" # OVH server flavor name. Choose one from https://www.ovhcloud.com/de/public-cloud/prices/#552.

  gateway_mode_enabled       = true # do not change

  # No worker nodes for single node gateway setup
  k3s_worker_nodes = [] # do not change

  # Admin public SSH keys with access to the node
  admin_ssh_key = {
    name       = "<your_admin_name>"
    public_key = "<your_public_ssh_key>"
  }

  # Optional: add more ssh keys to have access to the nodes
  additional_ssh_keys = [
    "<one_public_ssh_key>", "<another_public_ssh_key>"
  ]
}

# Don't change
output "k3s_controller_ip" {
  value = module.k3s.k3s_controller_ip[0]
}