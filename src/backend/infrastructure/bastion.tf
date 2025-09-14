data "yandex_compute_image" "bastion_image" {
  family = var.bastion_resources.image_name
}

resource "yandex_compute_instance" "bastion_vm" {
  name        = "bastion"
  platform_id = var.bastion_resources.platform_id
  resources {
    cores         = var.bastion_resources.cores
    memory        = var.bastion_resources.memory
    core_fraction = var.bastion_resources.core_fraction
  }
  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.worker_image.image_id
      size     = var.bastion_resources.disk_size
    }
  }
  scheduling_policy {
    preemptible = var.bastion_resources.is_preemptible
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.public_subnet.id
    nat       = var.bastion_resources.has_nat
  }

  metadata = local.vms_metadata
}

output "bastion_ip" {
  description = "External IP addresses of bastion"
  value       = yandex_compute_instance.bastion_vm.network_interface[0].nat_ip_address
}