resource "kubernetes_config_map_v1" "edge_config" {
  metadata {
    name      = "edge-config"
    labels = {
      app = "edge-service"
    }
  }

  data = {
    "application.yml" = file("${path.module}/app-conf/edge.yml")
    "application-prod.yml" = file("${path.module}/app-conf/edge-prod.yml")
  }

}


resource "kubernetes_deployment_v1" "edge_service_deployment" {
  depends_on = [kubernetes_deployment_v1.polar_postgres_deployment,
        kubernetes_deployment_v1.polar_rabbitmq_deployment,
        kubernetes_deployment_v1.polar_redis_deployment]
  metadata {
    name = "edge-service"
    labels = {
      app = "edge-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "edge-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "edge-service"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "9000"
        }
      }

      spec {
        container {
          name  = "edge-service"
          image = "ghcr.io/skyglass-books/edge-service:6617c515e62038dabf8e08666ed3d9a0472f1224"
          image_pull_policy = "Always"

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }

          resources {
            requests = {
              memory = "756Mi"
              cpu    = "0.1"
            }
            limits = {
              memory = "756Mi"
              cpu    = "2"
            }
          }          

          port {
            container_port = 9000
          }

          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "prod"
          }          

          env {
            name  = "EDGE_SERVICE_URL"
            value = "http://edge-service"
          }

          env {
            name  = "ORDER_SERVICE_URL"
            value = "http://order-service"
          }

          env {
            name  = "SPA_URL"
            value = "http://polar-ui"
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 9000
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 9000
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          volume_mount {
            name      = "edge-config-volume"
            mount_path = "/workspace/config"
          }

          volume_mount {
            name      = "redis-credentials-volume"
            mount_path = "/workspace/secrets/redis"
          }
          volume_mount {
            name      = "keycloak-client-credentials-volume"
            mount_path = "/workspace/secrets/keycloak-client"
          }
          volume_mount {
            name      = "keycloak-issuer-secret-volume"
            mount_path = "/workspace/secrets/keycloak-issuer"
          }

        }

        volume {
          name = "edge-config-volume"
          config_map {
            name = "edge-config"
          }
        }

        volume {
          name = "redis-credentials-volume"
          secret {
            secret_name = "polar-redis-credentials"
          }
        }
        volume {
          name = "keycloak-client-credentials-volume"
          secret {
            secret_name = "keycloak-server-client-credentials"
          }
        }
        volume {
          name = "keycloak-issuer-secret-volume"
          secret {
            secret_name = "keycloak-issuer-secret"
          }
        }        
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "edge_service_hpa" {
  metadata {
    name = "edge-service-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.edge_service_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "edge_service_service" {
  metadata {
    name = "edge-service"
  }
  spec {
    selector = {
      app = "edge-service"
    }
    port {
      port = 9000
    }
  }
}
