
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

variable "public_subnet" {
  type = object({
    name           = string
    v4_cidr_blocks = list(string)
  })
  default = {
    name           = "public"
    v4_cidr_blocks = ["192.168.10.0/24"]
  }
}

variable "private_subnet_configs" {
  type = list(object({
    zone      = string
    cidr      = string
    name_suffix = string
  }))
  default = [
    {
      zone      = "ru-central1-a"
      cidr      = "192.168.20.0/24"
      name_suffix = "a"
    },
    {
      zone      = "ru-central1-b"
      cidr      = "192.168.30.0/24"
      name_suffix = "b"
    },
    {
      zone      = "ru-central1-d"
      cidr      = "192.168.40.0/24"
      name_suffix = "d"
    }
  ]
}

# NAT

variable "nat_resources" {
  type = object({
    name           = string
    cores          = number
    memory         = number
    core_fraction  = number
    platform_id    = string
    image_id       = string
    zone           = string
    is_preemptible = bool
    ip_address     = string
    disk_size      = number
  })
  default = {
    name           = "nat-instance"
    cores          = 2
    memory         = 2
    core_fraction  = 20
    platform_id    = "standard-v2"
    image_id       = "fd80mrhj8fl2oe87o4e1"
    zone           = "ru-central1-d"
    is_preemptible = true
    ip_address     = "192.168.10.254"
    disk_size      = 10
  }
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
    has_nat        = true
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
    memory         = 2
    core_fraction  = 20
    platform_id    = "standard-v2"
    image_name     = "ubuntu-2204-lts"
    is_preemptible = true
    has_nat        = true
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

# Instance Group

variable "instance_group" {
  type = object({
    name        = string
    size        = number
    image_id    = string
    platform_id = string
    memory      = number
    cores       = number
    core_fraction = number
    is_preemptible = bool
    has_nat        = bool
    disk_size   = number
  })

  default = {
    name        = "lamp-ig"
    size        = 3
    image_id    = "fd827b91d99psvq5fjit"
    platform_id = "standard-v2"
    memory      = 2
    cores       = 2
    core_fraction = 20
    is_preemptible = true
    has_nat        = true
    disk_size   = 10
  }
}

# ALB

variable "alb_config" {
  type = object({
    name        = string
    domain      = optional(string, null)
    http_router_count = number
  })
  default = {
    name = "lamp-alb"
    http_router_count = 1
  }
}

# Hosting

variable "hoster_bucket_config" {
  type = object({
    name          = string
    size_gb       = number
    storage_class = string
    acl           = string
  })
  default = {
    name          = "xdcfyvgubhijnkml.ru"
    size_gb       = 1
    storage_class = "STANDARD"
    acl           = "public-read"
  }
  description = "S3 bucket configuration"
}

variable "hoster_service_account" {
  type = object({
    name        = string
    description = string
  })
  default = {
    name        = "hosting-sa"
    description = "Service account for S3 hostiing bucket"
  }
  description = "Service account configuration for the bucket"
}


variable "mysql_cluster_config" {
  type = object({
    name      = string
    environment = string
    version   = string
    deletion_protection = bool
    resource_preset_id = string
    disk_type_id = string
    disk_size = number
    maintenance_window = string
    backup_window_start_h = number
    backup_window_start_m = number
  })
  default = {
    name      = "netology-mysql-cluster"
    environment = "PRESTABLE"
    version   = "8.0"
    deletion_protection = true
    resource_preset_id = "b2.medium"
    disk_type_id = "network-hdd"
    disk_size = 20
    maintenance_window = "ANYTIME"
    backup_window_start_h = 23
    backup_window_start_m = 59
  }
}

variable "database_config" {
  type = object({
    db_name   = string
    user      = string
    password  = string
  })
  default = {
    db_name      = "netology_db"
    user      = "netology_user"
    password  = "secure_password_123"
  }
  sensitive = true
}

# Node Group

variable "k8s_ng_config" {
  type = object({
    name        = string
    version = string
    auto_scale = object({
      min = number
      max = number
      initial = number
    })
    deploy_policy = object({
      max_expansion = number
      max_unavailable = number
    })
  })
  default = {
    name = "k8s-demo-ng"
    version = "1.29"
    auto_scale = {
      initial = 3
      min = 1
      max = 6
    }
    deploy_policy = {
      max_unavailable = 1
      max_expansion = 1
    }
  }
}

variable "k8s_ng_template" {
  type = object({
    name        = string
    size        = number
    platform_id = string
    memory      = number
    cores       = number
    core_fraction = number
    is_preemptible = bool
    has_nat        = bool
    disk_type = string
    disk_size   = number
    network_acceleration_type = string
  })

  default = {
    name        = "k8s-node-group"
    size        = 3
    platform_id = "standard-v2"
    memory      = 2
    cores       = 2
    core_fraction = 20
    is_preemptible = true
    has_nat        = true
    disk_size   = 32
    disk_type = "network-hdd"
    network_acceleration_type = "standard"
  }
}