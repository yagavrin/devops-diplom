# Provider config

variable "cloud_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-d"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}

# S3

variable "tf_state_bucket" {
  type = object({
    name          = string
    size_gb       = number
    storage_class = string
    acl           = string
  })
  default = {
    name          = "yagavrin-tf-backend"
    size_gb       = 1
    storage_class = "STANDARD"
    acl           = "private"
  }
  description = "S3 bucket configuration"
}

variable "tf_state_kms_key" {
  type = object({
    name              = string
    description       = string
    default_algorithm = string
    rotation_period   = string
  })
  default = {
    name = "tf-state-kms-key"
    description       = "Encryption key for S3 bucket"
    default_algorithm = "AES_256"
    rotation_period   = "8760h"
  }
}