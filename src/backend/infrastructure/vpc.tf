resource "yandex_vpc_network" "dev_vpc" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "private_subnets" {
  for_each = { for idx, config in var.private_subnet_configs : idx => config }
  
  name           = "private-subnet-${each.value.name_suffix}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.dev_vpc.id
  v4_cidr_blocks = [each.value.cidr]
}

