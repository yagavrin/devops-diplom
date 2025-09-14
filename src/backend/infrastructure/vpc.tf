resource "yandex_vpc_network" "dev_vpc" {
  name = var.vpc_name
}

resource "yandex_vpc_subnet" "private_subnets" {
  for_each = { for idx, config in var.private_subnet_configs : idx => config }

  name           = "private-subnet-${each.value.name_suffix}"
  zone           = each.value.zone
  network_id     = yandex_vpc_network.dev_vpc.id
  v4_cidr_blocks = [each.value.cidr]
  route_table_id = yandex_vpc_route_table.rt.id
}

resource "yandex_vpc_subnet" "public_subnet" {
  name           = "public-subnet-1"
  zone           = var.public_subnet_config.zone
  network_id     = yandex_vpc_network.dev_vpc.id
  v4_cidr_blocks = var.public_subnet_config.cidr
}
