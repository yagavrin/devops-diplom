resource "yandex_container_registry" "container_registry" {
  name        = "default-registry"
  folder_id   = var.folder_id
  labels = {
    environment = "dev"
  }
}

output "registry_id" {
  value = yandex_container_registry.container_registry.id
}