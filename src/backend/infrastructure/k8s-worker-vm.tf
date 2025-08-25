# data "yandex_compute_image" "worker_image" {
#   family = var.k8s_worker_resources.image_name
# }

# resource "yandex_compute_instance" "k8s_worker_group" {
#   count = 2
#   name        = "k8s-worker-${count.index + 1}"
#   platform_id = var.k8s_worker_resources.platform_id
#   resources {
#     cores         = var.k8s_worker_resources.cores
#     memory        = var.k8s_worker_resources.memory
#     core_fraction = var.k8s_worker_resources.core_fraction
#   }
#   boot_disk {
#     initialize_params {
#       image_id = data.yandex_compute_image.worker_image.image_id
#       size     = var.k8s_worker_resources.disk_size
#     }
#   }
#   scheduling_policy {
#     preemptible = var.k8s_worker_resources.is_preemptible
#   }
#   network_interface {
#     subnet_id = yandex_vpc_subnet.private_subnets[2].id
#     nat       = var.k8s_worker_resources.has_nat
#     # security_group_ids = [yandex_vpc_security_group.example.id]
#   }

#   metadata = local.vms_metadata
# }