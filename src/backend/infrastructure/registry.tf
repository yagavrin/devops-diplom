resource "yandex_container_registry" "container_registry" {
  name      = "default-registry"
  folder_id = var.folder_id
  labels = {
    environment = "dev"
  }
}

resource "yandex_iam_service_account" "ycr_sa_pusher" {
  name        = "ycr-sa"
  description = "Service account for Yandex Container Registry"
}

resource "yandex_resourcemanager_folder_iam_member" "ycr_pusher" {
  folder_id = var.folder_id
  role      = "container-registry.images.pusher"
  member    = "serviceAccount:${yandex_iam_service_account.ycr_sa_pusher.id}"
}

resource "yandex_iam_service_account" "ycr_sa_puller" {
  name        = "ycr-puller-sa"
  description = "Service account for pulling images from Yandex Container Registry"
}

resource "yandex_resourcemanager_folder_iam_member" "registry_puller" {
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  member    = "serviceAccount:${yandex_iam_service_account.ycr_sa_puller.id}"
}

output "registry_id" {
  value = yandex_container_registry.container_registry.id
}

output "ycr_sa_pusher_id" {
  value = yandex_iam_service_account.ycr_sa_pusher.id
}

output "ycr_sa_puller_id" {
  value = yandex_iam_service_account.ycr_sa_puller.id
}
