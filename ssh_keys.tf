resource "ovh_cloud_project_ssh_key" "admin" {
  service_name = var.ovh_service_name
  public_key   = var.admin_ssh_key.public_key
  name         = var.admin_ssh_key.name
}