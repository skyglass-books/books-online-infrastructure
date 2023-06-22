# Resource: Config Map
resource "kubernetes_config_map_v1" "keycloak_server_configmap" {
  metadata {
    name = "keycloak-server-config"
  }

  data = {
  "realm-config.json" = "${file("${path.module}/keycloak-server-config.yml")}"
  }
} 