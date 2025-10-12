resource "yandex_vpc_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  network_id  = yandex_vpc_network.dev_vpc.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outbound traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "k8s_private" {
  name        = "k8s-private-sg"
  description = "Security group for Kubernetes private nodes"
  network_id  = yandex_vpc_network.dev_vpc.id

  ingress {
    protocol = "TCP" 
    description = "SSH for bastion" 
    port = 22 
    v4_cidr_blocks = ["${yandex_compute_instance.bastion_vm.network_interface[0].ip_address}/32"] 
  }

  ingress { 
    protocol = "TCP" 
    description = "Kubernetes API server" 
    port = 6443 
    v4_cidr_blocks = ["${yandex_compute_instance.bastion_vm.network_interface[0].ip_address}/32"] 
  }

  # Allow all traffic within this SG (cluster internal communication)
  ingress {
    protocol          = "TCP"
    description       = "Cluster internal TCP"
    predefined_target = "self_security_group"
    from_port = 1
    to_port = 65535
  }

  ingress {
    protocol          = "UDP"
    description       = "Cluster internal UDP"
    predefined_target = "self_security_group"
    from_port = 1
    to_port = 65535
  }

  ingress {
    protocol          = "ICMP"
    description       = "Cluster internal ICMP"
    predefined_target = "self_security_group"
  }

  # Allow health checks from Yandex NLB
  ingress {
    protocol          = "TCP"
    description       = "Allow NLB traffik"
    from_port = 30000
    to_port = 32767
    v4_cidr_blocks = ["0.0.0.0/0"]
  }



  ingress {
    protocol          = "TCP"
    description       = "Allow NLB health checks"
    port              = 10250
    predefined_target = "loadbalancer_healthchecks"
  }

    ingress {
    protocol          = "TCP"
    description       = "Allow NLB health checks"
    port              = 6443
    predefined_target = "loadbalancer_healthchecks"
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "atlantis_sg" {
  name        = "atlantis-sg"
  description = "Security group for Atlantis"
  network_id  = yandex_vpc_network.dev_vpc.id

  ingress {
    protocol = "TCP" 
    description = "SSH" 
    port = 22 
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol          = "TCP"
    description       = "Allow incoming webhooks from Github"
    port              = 4141
    # https://api.github.com/meta  hooks
    v4_cidr_blocks = [
      "185.199.108.0/22",
      "140.82.112.0/20",
      "143.55.64.0/20"
    ]
  }

  egress {
    protocol       = "ANY"
    description    = "Allow all outgoing traffic"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}