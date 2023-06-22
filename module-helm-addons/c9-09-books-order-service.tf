resource "kubernetes_config_map_v1" "order_config" {
  metadata {
    name      = "order-config"
    labels = {
      app = "order-service"
    }
  }

  data = {
    "application.yml" = file("${path.module}/app-conf/order.yml")
    "application-prod.yml" = file("${path.module}/app-conf/order-prod.yml")
  }
}


resource "kubernetes_deployment_v1" "order_service_deployment" {
  depends_on = [kubernetes_deployment_v1.polar_postgres_deployment,
                kubernetes_deployment_v1.polar_rabbitmq_deployment,
                kubernetes_deployment_v1.polar_redis_deployment]    
  metadata {
    name = "order-service"

    labels = {
      app = "order-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "order-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "order-service"
        }

        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "9002"
        }
      }

      spec {
        container {
          name  = "order-service"
          image = "ghcr.io/skyglass-books/order-service:80a076cf50802a28c27e6eb4772904ed4ab1bbe7"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "prod"
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

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }

          port {
            container_port = 9002
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 9002
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 9002
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          volume_mount {
            name      = "order-config-volume"
            mount_path = "/workspace/config"
          }

          volume_mount {
            name       = "postgres-credentials-volume"
            mount_path = "/workspace/secrets/postgres"
          }

          volume_mount {
            name       = "rabbitmq-credentials-volume"
            mount_path = "/workspace/secrets/rabbitmq"
          }

          volume_mount {
            name       = "keycloak-issuer-secret-volume"
            mount_path = "/workspace/secrets/keycloak"
          }          
        }

        volume {
          name = "order-config-volume"
          config_map {
            name = "order-config"
          }
        }

        volume {
          name = "postgres-credentials-volume"

          secret {
            secret_name = "polar-postgres-order-credentials"
          }
        }

        volume {
          name = "rabbitmq-credentials-volume"

          secret {
            secret_name = "polar-rabbitmq-credentials"
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

resource "kubernetes_horizontal_pod_autoscaler_v1" "order_service_hpa" {
  metadata {
    name = "order-service-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.order_service_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "order_service_service" {
  metadata {
    name = "order-service"
  }
  spec {
    selector = {
      app = "order-service"
    }
    port {
      port = 9002
    }
  }
}
