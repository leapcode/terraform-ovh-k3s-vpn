locals {
  # Controller lookup
  controller_flavor_matches = [for f in data.ovh_cloud_project_flavors.all.flavors : f if f.name == var.k3s_controller_server_type]
  controller_flavor_id      = length(local.controller_flavor_matches) > 0 ? local.controller_flavor_matches[0].id : null

  # Lookup for base os
  base_os_matches  = [for img in data.ovh_cloud_project_images.all.images : img if(img.name == var.k3s_base_os)]
  base_os_image_id = length(local.base_os_matches) > 0 ? local.base_os_matches[0].id : null

  # Expand each worker node group into a flat list of VMs with unique names and turn flavor and image names into ids
  k3s_worker_nodes = flatten([
    for group in var.k3s_worker_nodes : [
      for i in range(group.count) : {
        name       = "${group.name}-${i + 1}"
        group_name = group.name
        # Dynamically select the flavor-id based on the flavor name of each worker node group
        flavor_id = length([
          for f in data.ovh_cloud_project_flavors.all.flavors :
          f if f.name == group.server_type
          ]) > 0 ? (
          [for f in data.ovh_cloud_project_flavors.all.flavors : f if f.name == group.server_type][0].id
        ) : null
        # Dynamically select the image-id based on the image name of each worker node group, default to k3s_base_os
        image_id = length(group.image_name != null ? [
          for img in data.ovh_cloud_project_images.all.images : img if img.name == group.image_name
          ] : []) > 0 ? (
          [for img in data.ovh_cloud_project_images.all.images : img if img.name == group.image_name][0].id
        ) : local.base_os_image_id
      }
    ]
  ])

  # Collect all failed flavor lookups
  flavor_lookup_failures = concat(
    [for node in local.k3s_worker_nodes : node.name if node.flavor_id == null],
    local.controller_flavor_id == null ? ["controller"] : []
  )

  # Collect all image lookup failures (workers + controller)
  image_lookup_failures = concat(
    [for node in local.k3s_worker_nodes : node.name if node.image_id == null && (lookup(node, "image_name", null) != null)],
    local.base_os_image_id == null ? ["controller"] : []
  )
}

# Fail terraform if any flavor lookup failed
resource "null_resource" "fail_on_missing_flavors" {
  count = length(local.flavor_lookup_failures) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      echo "Flavor lookup failed for nodes: ${join(", ", local.flavor_lookup_failures)}"
      exit 1
    EOT
  }
}

# Fail terraform if any image lookup failed
resource "null_resource" "fail_on_missing_images" {
  count = length(local.image_lookup_failures) > 0 ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      echo "Image lookup failed for nodes: ${join(", ", local.image_lookup_failures)}"
      exit 1
    EOT
  }
}


output "resolved_worker_nodes" {
  value = local.k3s_worker_nodes
}
