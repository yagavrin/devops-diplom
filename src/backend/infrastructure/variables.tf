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


# user config

variable "vms_metadata" {
  type = map(string)
  default = {
    ssh-keys = "ubuntu:ssh-ed25519 AAAAC..."
  }
}
variable "vm_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_pub_key_path" {
  type    = string
  default = "~/.ssh/nt_test.pub"
}

# VPC config

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network name"
}

variable "public_subnet_config" {
  type = object({
    zone = string
    name = string
    cidr = list(string)
  })
  default = {
    zone = "ru-central1-d"
    name = "public"
    cidr = ["192.168.10.0/24"]
  }
}

variable "private_subnet_configs" {
  type = list(object({
    zone        = string
    cidr        = string
    name_suffix = string
  }))
  default = [
    {
      zone        = "ru-central1-a"
      cidr        = "192.168.20.0/24"
      name_suffix = "a"
    },
    {
      zone        = "ru-central1-b"
      cidr        = "192.168.30.0/24"
      name_suffix = "b"
    },
    {
      zone        = "ru-central1-d"
      cidr        = "192.168.40.0/24"
      name_suffix = "d"
    }
  ]
}

# VM
variable "k8s_cp_resources" {
  type = object({
    cores          = number
    memory         = number
    core_fraction  = number
    platform_id    = string
    image_name     = string
    is_preemptible = bool
    has_nat        = bool
    disk_size      = number
  })
  default = {
    cores          = 4
    memory         = 8
    core_fraction  = 20
    platform_id    = "standard-v2"
    image_name     = "ubuntu-2204-lts"
    is_preemptible = true
    has_nat        = false
    disk_size      = 50
  }
}

variable "k8s_worker_resources" {
  type = object({
    cores          = number
    memory         = number
    core_fraction  = number
    platform_id    = string
    image_name     = string
    is_preemptible = bool
    has_nat        = bool
    disk_size      = number
  })
  default = {
    cores          = 2
    memory         = 4
    core_fraction  = 20
    platform_id    = "standard-v2"
    image_name     = "ubuntu-2204-lts"
    is_preemptible = true
    has_nat        = false
    disk_size      = 20
  }
}

variable "atlantis_resources" {
  type = object({
    cores          = number
    memory         = number
    core_fraction  = number
    platform_id    = string
    image_name     = string
    is_preemptible = bool
    has_nat        = bool
    disk_size      = number
  })
  default = {
    cores          = 2
    memory         = 2
    core_fraction  = 20
    platform_id    = "standard-v2"
    image_name     = "ubuntu-2204-lts"
    is_preemptible = true
    has_nat        = true
    disk_size      = 20
  }
}

variable "bastion_resources" {
  type = object({
    cores          = number
    memory         = number
    core_fraction  = number
    platform_id    = string
    image_name     = string
    is_preemptible = bool
    has_nat        = bool
    disk_size      = number
  })
  default = {
    cores          = 2
    memory         = 2
    core_fraction  = 20
    platform_id    = "standard-v2"
    image_name     = "ubuntu-2204-lts"
    is_preemptible = true
    has_nat        = true
    disk_size      = 20
  }
}