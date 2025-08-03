resource "yandex_iam_service_account" "ccm_ca" {
  name        = "ccm-ca"
  description = "Service account for Yandex Cloud Controller Manager"
}

resource "yandex_resourcemanager_folder_iam_member" "ccm_lb_admin" {
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  member    = "serviceAccount:${yandex_iam_service_account.ccm_ca.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "ccm_vpc_admin" {
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  member    = "serviceAccount:${yandex_iam_service_account.ccm_ca.id}"
}

resource "yandex_iam_service_account_key" "ccm_key" {
  service_account_id = yandex_iam_service_account.ccm_ca.id
  description        = "Key for CCM"
}

resource "local_file" "ccm_key_file" {
  content  = yandex_iam_service_account_key.ccm_key.private_key
  filename = "${path.module}/sa-key.json"
}
