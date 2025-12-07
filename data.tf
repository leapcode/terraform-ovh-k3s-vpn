data "ovh_cloud_project_flavors" "all" {
  service_name = var.ovh_service_name
  region = var.ovh_region
}

data "ovh_cloud_project_images" "all" {
  service_name = var.ovh_service_name
  region = var.ovh_region
}