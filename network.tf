resource "ovh_cloud_project_network_private" "k3s_network" {
  service_name = var.ovh_service_name
  name         = var.k3s_network_name
  regions      = [var.ovh_region]
}

resource "ovh_cloud_project_network_private_subnet_v2" "controllers" {
  service_name = var.ovh_service_name
  network_id = element([
    for region in ovh_cloud_project_network_private.k3s_network.regions_attributes :
    region.openstackid if region.region == var.ovh_region
  ], 0)
  name       = "subnet-controllers"
  cidr       = "172.16.0.0/24"
  region     = var.ovh_region
  depends_on = [ovh_cloud_project_network_private.k3s_network]
}

resource "ovh_cloud_project_network_private_subnet_v2" "workers" {
  for_each     = { for group in var.k3s_worker_nodes : group.name => group }
  service_name = var.ovh_service_name
  network_id = element([
    for region in ovh_cloud_project_network_private.k3s_network.regions_attributes :
    region.openstackid if region.region == var.ovh_region
  ], 0)
  name       = "subnet-workers-${each.key}"
  cidr       = cidrsubnet("172.16.0.0/16", 8, 1 + index(keys({ for group in var.k3s_worker_nodes : group.name => group }), each.key))
  region     = var.ovh_region
  depends_on = [ovh_cloud_project_network_private.k3s_network]
}