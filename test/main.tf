terraform {
  required_version = ">= 1.5"
  backend "local" {}
}

provider "random" {}

resource "random_id" "demo" {
  byte_length = 2
}
