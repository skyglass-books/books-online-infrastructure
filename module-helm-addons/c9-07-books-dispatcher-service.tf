resource "kubernetes_config_map" "catalog_config" {
  metadata {
    name      = "catalog-config"
    labels = {
      app = "catalog-service"
    }
  }

  data = {
    "application.yml" = file("${path.module}/app-conf/catalog.yml")
    "application-prod.yml" = file("${path.module}/app-conf/catalog-prod.yml")
  }

  merge_behavior = "merge"
}


resource "kubernetes_deployment" "dispatcher_service" {
  metadata {
    name = "dispatcher-service"
    labels = {
      app = "dispatcher-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "dispatcher-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "dispatcher-service"
        }
        annotations = {
          "prometheus.io/scrape" = "true"
          "prometheus.io/path"   = "/actuator/prometheus"
          "prometheus.io/port"   = "9003"
        }
      }

      spec {
        container {
          name  = "dispatcher-service"
          image = "dispatcher-service"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "SPRING_PROFILES_ACTIVE"
            value = "prod"
          }

          resources {
            requests {
              memory = "756Mi"
              cpu    = "0.1"
            }

            limits {
              memory = "756Mi"
              cpu    = "2"
            }
          }                   

          lifecycle {
            pre_stop {
              exec {
                command = [ "sh", "-c", "sleep 5" ]
              }
            }
          }

          ports {
            container_port = 9003
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 9003
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 9003
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          volume_mount {
            name       = "dispatcher-config-volume"
            mount_path = "/workspace/config"
          }

          volume_mount {
            name      = "rabbitmq-credentials-volume"
            mount_path = "/workspace/secrets/rabbitmq"
          }          
        }

        volume {
          name = "dispatcher-config-volume"
          config_map {
            name = "dispatcher-config"
          }
        }

        volume {
          name = "rabbitmq-credentials-volume"
          secret {
            secret_name = "polar-rabbitmq-credentials"
          }
        }        
      }
    }
  }
}

resource "kubernetes_horizontal_pod_autoscaler_v1" "catalog_service_hpa" {
  metadata {
    name = "catalog-service-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.catalog_service_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "catalog_service_service" {
  metadata {
    name = "catalog-service"
  }
  spec {
    selector = {
      app = "catalog-service"
    }
    port {
      port = 9003
    }
  }
}
