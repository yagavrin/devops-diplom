resource "yandex_storage_bucket" "s3_bucket" {
  bucket     = var.tf_state_bucket.name
  access_key = yandex_iam_service_account_static_access_key.sa_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_key.secret_key

  max_size = local.bucket_size_bytes

  default_storage_class = var.tf_state_bucket.storage_class
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.kms-key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

# Создание статического ключа доступа
resource "yandex_iam_service_account_static_access_key" "sa_key" {
  service_account_id = yandex_iam_service_account.tf_s3_sa.id
  description        = "Static access key for S3 bucket ${var.tf_state_bucket.name}"
}

output "tf_backend_access_key" {
  value       = yandex_iam_service_account_static_access_key.sa_key.access_key
  description = "Access key for S3 backend"
  sensitive   = true
}

output "tf_backend_secret_key" {
  value       = yandex_iam_service_account_static_access_key.sa_key.secret_key
  description = "Secret key for S3 backend"
  sensitive   = true
}