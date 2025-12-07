resource "ovh_cloud_project_instance" "k3s_controller" {
  count          = var.k3s_leader_count
  name           = "${var.k3s_cluster_name}-controller-${count.index}"
  service_name   = var.ovh_service_name
  region         = var.ovh_region
  billing_period = "hourly"
  boot_from {
    image_id = local.base_os_image_id
  }
  flavor {
    flavor_id = local.controller_flavor_id
  }
  ssh_key {
    name = ovh_cloud_project_ssh_key.admin.name
  }
  user_data = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                file("${path.module}/templates/cloud-config.yml"),
                # TODO: Multi-leader disabled for now since it leads to cyclic definition
                "__LEADER_IP__", ""
                # [
                #   for item in ovh_cloud_project_instance.k3s_controller.addresses : item.ip
                #   if item.version == 4 && (
                #     startswith(item.ip, "172.16.")
                #   )
                # ][0]
              ),
              "__GATEWAY_MODE_ENABLED__", var.gateway_mode_enabled
            ),
            "__LEADER_COUNT__", count.index
          ),
          "__TOTAL_LEADERS__", var.k3s_leader_count
        ),
        "__SSH_KEYS__",
        length(var.additional_ssh_keys) > 0 ?
        "ssh_authorized_keys:\n${join("\n", [for key in var.additional_ssh_keys : format("  - %s", key)])}" :
        ""
      ),
      "__K3S_TOKEN__", random_password.k3s_token.result
    ),
    "__K3S_IP__", ""
  )

  network {
    public = true
    private {
      network {
        id = element([
          for region in ovh_cloud_project_network_private.k3s_network.regions_attributes :
          region.openstackid if region.region == var.ovh_region
        ], 0)
        subnet_id = ovh_cloud_project_network_private_subnet_v2.controllers.id
      }
    }
  }
  depends_on = [ovh_cloud_project_network_private_subnet_v2.controllers]
}

resource "random_password" "k3s_token" {
  length  = 48
  special = false
}

output "controller_public_ip" {
  value = [
    for item in ovh_cloud_project_instance.k3s_controller[0].addresses : item.ip
    if item.version == 4 &&
    !startswith(item.ip, "172.16.") &&
    !strcontains(item.ip, ":")
  ]
}