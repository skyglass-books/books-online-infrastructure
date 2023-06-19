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


resource "kubernetes_deployment" "catalog_service_deployment" {
  metadata {
    name = "catalog-service"

    labels = {
      app = "catalog-service"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "catalog-service"
      }
    }

    template {
      metadata {
        labels = {
          app = "catalog-service"
        }

        annotations = {
          "prometheus.io/scrape" : "true"
          "prometheus.io/path"   : "/actuator/prometheus"
          "prometheus.io/port"   : "9001"
        }
      }

      spec {
        container {
          name = "catalog-service"
          image = "catalog-service"
          image_pull_policy = "IfNotPresent"

          env {
            name  = "BPL_JVM_THREAD_COUNT"
            value = "100"
          }

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
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }

          ports {
            container_port = 9001
          }

          liveness_probe {
            http_get {
              path = "/actuator/health/liveness"
              port = 9001
            }
            initial_delay_seconds = 10
            period_seconds        = 5
          }

          readiness_probe {
            http_get {
              path = "/actuator/health/readiness"
              port = 9001
            }
            initial_delay_seconds = 5
            period_seconds        = 15
          }

          volume_mount {
            name       = "catalog-config-volume"
            mount_path = "/workspace/config"
          }          

          volume_mount {
            name      = "postgres-credentials-volume"
            mountPath = "/workspace/secrets/postgres"
          }

          volume_mount {
            name      = "keycloak-issuer-resourceserver-secret-volume"
            mountPath = "/workspace/secrets/keycloak"
          }
        }

        volume {
          name = "catalog-config-volume"
          config_map {
            name = "catalog-config"
          }
        }        

        volume {
          name = "postgres-credentials-volume"
          secret {
            secret_name = "polar-postgres-catalog-credentials"
          }
        }

        volume {
          name = "keycloak-issuer-resourceserver-secret-volume"
          secret {
            secret_name = "keycloak-issuer-resourceserver-secret"
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
      port = 9001
    }
  }
}
