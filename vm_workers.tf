resource "ovh_cloud_project_instance" "k3s_worker" {
  for_each       = { for idx, node in local.k3s_worker_nodes : node.name => node }
  name           = "${var.k3s_cluster_name}-worker-${each.key}"
  service_name   = var.ovh_service_name
  region         = var.ovh_region
  billing_period = "hourly"
  boot_from {
    image_id = each.value.image_id
  }
  flavor {
    flavor_id = each.value.flavor_id
  }
  ssh_key {
    name = ovh_cloud_project_ssh_key.admin.name
  }
  # Fill in arguments in cloud_init script
  user_data = replace(
    replace(
      replace(
        replace(
          replace(
            replace(
              replace(
                file("${path.module}/templates/cloud-config.yml"),
                # TODO: check if this still works with multi-leader
                "__LEADER_IP__", [
                  for item in ovh_cloud_project_instance.k3s_controller[0].addresses : item.ip
                  if item.version == 4 && (
                    startswith(item.ip, "172.16.")
                  )
                ][0]
              ),
              "__GATEWAY_MODE_ENABLED__", var.gateway_mode_enabled
            ),
            "__LEADER_COUNT__", ""
          ),
          "__TOTAL_LEADERS__", ""
        ),
        "__SSH_KEYS__",
        length(var.additional_ssh_keys) > 0 ?
        "ssh_authorized_keys:\n${join("\n", [for key in var.additional_ssh_keys : format("  - %s", key)])}" :
        ""
      ),
      "__K3S_TOKEN__", random_password.k3s_token.result
    ),
    "__K3S_IP__", [
      for item in ovh_cloud_project_instance.k3s_controller[0].addresses : item.ip
      if item.version == 4 && (
        startswith(item.ip, "172.16.")
      )
    ][0]
  )
  network {
    public = true
    private {
      network {
        id = element([
          for region in ovh_cloud_project_network_private.k3s_network.regions_attributes :
          region.openstackid if region.region == var.ovh_region
        ], 0)
        subnet_id = ovh_cloud_project_network_private_subnet_v2.workers[each.value.group_name].id
      }
    }
  }
  depends_on = [ovh_cloud_project_instance.k3s_controller]
}
