# resource "yandex_lb_target_group" "k8s_ingress_targets" {
#   name      = "k8s-target-group"

#   dynamic "target" {
#     for_each = concat(
#       yandex_compute_instance.k8s_cp_group[*],
#       yandex_compute_instance.k8s_worker_group[*]
#     )
#     content {
#       subnet_id = target.value.network_interface.0.subnet_id
#       address   = target.value.network_interface.0.ip_address
#     }
#   }
# }

# resource "yandex_lb_network_load_balancer" "k8s_ingress_lb" {
#   name               = "k8s-ingress-lb"
#   type               = "external"
#   listener {
#     name = "http"
#     port = 80
#     external_address_spec {
#       ip_version = "ipv4"
#     }
#   }

#   attached_target_group {
#     target_group_id = yandex_lb_target_group.k8s_ingress_targets.id
#     healthcheck {
#       name = "http"
#       http_options {
#         port = 80
#         path = "/"
#       }
#     }
#   }
# }