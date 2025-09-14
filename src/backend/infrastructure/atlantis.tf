# data "yandex_compute_image" "atlantis_image" {
#   family = var.atlantis_resources.image_name
# }

# resource "yandex_compute_instance" "atlantis_vm" {
#   name        = "atlantis"
#   platform_id = var.atlantis_resources.platform_id
#   resources {
#     cores         = var.atlantis_resources.cores
#     memory        = var.atlantis_resources.memory
#     core_fraction = var.atlantis_resources.core_fraction
#   }
#   boot_disk {
#     initialize_params {
#       image_id = data.yandex_compute_image.atlantis_image.image_id
#       size     = var.atlantis_resources.disk_size
#     }
#   }
#   scheduling_policy {
#     preemptible = var.atlantis_resources.is_preemptible
#   }
#   network_interface {
#     subnet_id = yandex_vpc_subnet.private_subnets[2].id
#     nat       = var.atlantis_resources.has_nat
#     # security_group_ids = [yandex_vpc_security_group.example.id]
#   }

#   metadata = local.vms_metadata
# }

# output "atlantis_vm_ip" {
#   value       = yandex_compute_instance.atlantis_vm.network_interface[0].nat_ip_address
#   description = "Atlantis server IP"
# }