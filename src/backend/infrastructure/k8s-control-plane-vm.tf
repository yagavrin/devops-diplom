data "yandex_compute_image" "manager_image" {
  family = var.k8s_cp_resources.image_name
}

resource "yandex_compute_instance" "k8s_cp_group" {
  count       = 1
  name        = "k8s-cp-${count.index + 1}"
  platform_id = var.k8s_cp_resources.platform_id
  resources {
    cores         = var.k8s_cp_resources.cores
    memory        = var.k8s_cp_resources.memory
    core_fraction = var.k8s_cp_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.manager_image.image_id
      size     = var.k8s_cp_resources.disk_size
    }
  }
  scheduling_policy {
    preemptible = var.k8s_cp_resources.is_preemptible
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.private_subnets[2].id
    nat       = var.k8s_cp_resources.has_nat
    security_group_ids = [ yandex_vpc_security_group.k8s_private.id ]
  }

  metadata = local.vms_metadata
}

output "k8s_cp_vm_ip" {
  value       = yandex_compute_instance.k8s_cp_group[0].network_interface[0].ip_address
  description = "Internal IP addresses of k8s CP"
}
