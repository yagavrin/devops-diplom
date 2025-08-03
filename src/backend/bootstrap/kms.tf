resource "yandex_kms_symmetric_key" "kms-key" {
  name              = var.tf_state_kms_key.name
  description       = var.tf_state_kms_key.description
  default_algorithm = var.tf_state_kms_key.default_algorithm
  rotation_period   = var.tf_state_kms_key.rotation_period
}