# Создание сервисного аккаунта
resource "yandex_iam_service_account" "tf_s3_sa" {
  name        = "${var.tf_state_bucket.name}-sa"
  description = "Service account for ${var.tf_state_bucket.name}"
}

# Назначение роли сервисному аккаунту
resource "yandex_resourcemanager_folder_iam_member" "s3_admin" {
  folder_id = var.folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.tf_s3_sa.id}"
}

resource "yandex_kms_symmetric_key_iam_member" "kms_key_access" {
  symmetric_key_id = yandex_kms_symmetric_key.kms-key.id
  role   = "kms.keys.encrypterDecrypter"
  member = "serviceAccount:${yandex_iam_service_account.tf_s3_sa.id}"
}