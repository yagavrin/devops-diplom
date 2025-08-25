resource "yandex_container_registry" "container_registry" {
  name        = "default-registry"
  folder_id   = var.folder_id
  labels = {
    environment = "dev"
  }
}

resource "yandex_iam_service_account" "ycr_sa" {
  name        = "ycr-sa"
  description = "Service account for Yandex Container Registry"
}

resource "yandex_resourcemanager_folder_iam_member" "ycr_pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.ycr_sa.id}"
}


output "registry_id" {
  value = yandex_container_registry.container_registry.id
}

output "ycr_sa_id" {
  value = yandex_iam_service_account.ycr_sa.id
}