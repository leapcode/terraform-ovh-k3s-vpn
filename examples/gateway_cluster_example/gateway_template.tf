# Template file for a single-node cluster to use as a gateway
# Copy it to a new directory, outside of this repository.

module "k3s" {
  # Use the existing k3s module from parent directory
  source = "git::https://0xacab.org/leap/container-platform/terraform-ovh-k3s-vpn.git?ref=no-masters"

  # OVH Project details
  ovh_service_name = "<id_of_your_ovh_public_cloud_project>"  # ⚠️ Fill in your public cloud project ID
  ovh_region       = "<ovh_public_cloud_datacenter_location>" # ⚠️ Fill in the regional code of the datacenter location

  # Cluster name
  k3s_cluster_name = "gateway-location" # ⚠️ Choose a name wrt gateway location

  # Network configuration
  k3s_network_name = "gateway-location-network" # ⚠️ Choose a name wrt gateway location

  # Controller node server configuration
  k3s_controller_server_type = "b2-7" # ⚠️ OVH server flavor name. Choose one from https://www.ovhcloud.com/de/public-cloud/prices/#552.

  gateway_mode_enabled = true # do not change

  # No worker nodes for single node gateway setup
  k3s_worker_nodes = [] # do not change

  # Admin public SSH keys with access to the node
  admin_ssh_key = { # ⚠️ Add admin ssh key
    name       = "<your_admin_name>"
    public_key = "<your_public_ssh_key>"
  }

  # Optional: more ssh keys to have access to the nodes
  additional_ssh_keys = [ # ⚠️ Add other public ssh keys or delete
    "<one_public_ssh_key>", "<another_public_ssh_key>"
  ]
}

# Don't change
output "k3s_controller_ip" {
  value = module.k3s.k3s_controller_ip[0]
}
