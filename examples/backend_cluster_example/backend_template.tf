# Template for a multi-node cluster for backend components
# Copy it to a new directory, outside of this repository.

module "k3s" {
  # Use the existing k3s module from parent directory
  source = "git::https://0xacab.org/leap/container-platform/terraform-ovh-k3s-vpn.git?ref=no-masters"

  # OVH Project details
  ovh_service_name = "<id_of_your_ovh_public_cloud_project>"  # ⚠️ Fill in your public cloud project ID
  ovh_region       = "<ovh_public_cloud_datacenter_location>" # ⚠️ Fill in the regional code of the datacenter location

  # Cluster name
  k3s_cluster_name = "backend-cluster"

  # Network configuration
  k3s_network_name = "backend-cluster-network"

  # Controller node server configuration
  k3s_controller_server_type = "b2-7" # ⚠️ OVH server flavor name. Choose one from https://www.ovhcloud.com/de/public-cloud/prices/#552.

  gateway_mode_enabled = false # do not change

  # Setup with two worker nodes
  # Check vars.tf to see all available properties of the k3s_worker_nodes object
  k3s_worker_nodes = [
    {
      name        = "menshen"
      count       = 1
      server_type = "b2-7" # ⚠️ Check if this server flavor is available in your chosen location or choose other server type
    },
    {
      name        = "monitoring"
      count       = 1
      server_type = "b2-7" # ⚠️ Check if this server flavor is available in your chosen location or choose other server type
    }
  ]

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
