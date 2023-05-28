# Install Keycloak Server using Kubernetes Deployment
# Resource: Keycloak Kubernetes Deployment
resource "kubernetes_deployment_v1" "keycloak_server" {
  depends_on = [kubernetes_deployment_v1.keycloak_postgres_deployment]
  metadata {
    name = "keycloak-server"
    labels = {
      app = "keycloak-server"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "keycloak-server"
      }
    }
    template {
      metadata {
        labels = {
          app = "keycloak-server"
        }
      }
      spec {
        volume {
          name = "keycloak-server-config-volume"    
          config_map {
            name = kubernetes_config_map_v1.keycloak_server_config_map.metadata.0.name
          }
        }
        container {
          image = "quay.io/keycloak/keycloak:20.0.3"
          name  = "keycloak-server"
          args  = ["start-dev"]
          #image_pull_policy = "always"  # Defaults to Always so we can comment this
          port {
            container_port = 8080
          }
          env {
            name = "JAVA_OPTS_APPEND"
            value = "-Dkeycloak.import=/opt/keycloak/data/import/realm-config.json"
          }          
          env {
            name = "KEYCLOAK_ADMIN"
            value = "admin"
          }
          env {
            name = "KEYCLOAK_ADMIN_PASSWORD"
            value = "admin"
          }
          env {
            name = "KC_DB"
            value = "postgres"
          }
          env {
            name = "KC_DB_URL_HOST"
            value = "keycloak-postgres"
          }
          env {
            name = "KC_DB_DATABASE"
            value = "keycloak"
          }
          env {
            name = "KC_DB_USERNAME"
            value = "postgres"
          }
          env {
            name = "KC_DB_SCHEMA"
            value = "public"
          }
          env {
            name = "KC_DB_PASSWORD"
            value = "postgres"
          }  
          env {
            name = "KC_HOSTNAME"
            value = "keycloak.greeta.net"
          }
          env {
            name = "KC_PROXY"
            value = "edge"
          }

          volume_mount {
            name = "keycloak-server-config-volume"
            mount_path = "/opt/keycloak/data/import"
          }
        }
      }
    }
  }
}

# Resource: Keycloak Server Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "keycloak_server_hpa" {
  metadata {
    name = "keycloak-server-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.keycloak_server.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "keycloak_server_service" {
  metadata {
    name = "keycloak-server"
  }
  spec {
    selector = {
      app = "keycloak-server"
    }
    port {
      port = 8080
    }
  }
}
