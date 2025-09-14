resource "yandex_lb_network_load_balancer" "k8s-ingress-lb" {
  name = "k8s-ingress-nlb"

  listener {
    name        = "http"
    port        = 80
    protocol    = "tcp"
    target_port = 80
  }

  listener {
    name        = "https"
    port        = 443
    protocol    = "tcp"
    target_port = 443
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-worker-tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/healthz"
      }
    }

  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.k8s-cp-tg.id

    healthcheck {
      name = "tcp"
      tcp_options {
        port = 6443
      }
    }

  }

}

resource "yandex_lb_target_group" "k8s-worker-tg" {
  name = "k8s-worker-nodes"

  dynamic "target" {
    for_each = yandex_compute_instance.k8s_worker_group
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}

resource "yandex_lb_target_group" "k8s-cp-tg" {
  name = "k8s-cp-nodes"

  dynamic "target" {
    for_each = yandex_compute_instance.k8s_cp_group
    content {
      subnet_id = target.value.network_interface.0.subnet_id
      address   = target.value.network_interface.0.ip_address
    }
  }
}