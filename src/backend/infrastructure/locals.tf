locals {
  vms_metadata = { ssh-keys = "${var.vm_user}:${file(var.ssh_pub_key_path)}" }
}