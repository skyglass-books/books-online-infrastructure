resource "kubernetes_deployment" "polar_ui_deployment" {
  metadata {
    name = "polar-ui"

    labels = {
      app = "polar-ui"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "polar-ui"
      }
    }

    template {
      metadata {
        labels = {
          app = "polar-ui"
        }
      }

      spec {
        container {
          name = "polar-ui"
          image = "ghcr.io/polarbookshop/polar-ui:v1"
          image_pull_policy = "Always"

          lifecycle {
            pre_stop {
              exec {
                command = ["sh", "-c", "sleep 5"]
              }
            }
          }

          ports {
            container_port = 9004
          }

          env {
            name  = "PORT"
            value = "9004"
          }

          resources {
            requests {
              memory = "128Mi"
              cpu    = "0.1"
            }

            limits {
              memory = "512Mi"
              cpu    = "2"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "polar_ui_service" {
  metadata {
    name = "polar-ui"

    labels = {
      app = "polar-ui"
    }
  }

  spec {

    selector = {
      app = "polar-ui"
    }

    ports {
      port = 9004
    }
  }
}

# Resource: Books UI Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "books_ui_hpa" {
  metadata {
    name = "books-ui-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.books_ui_deployment.metadata[0].name
    }
    target_cpu_utilization_percentage = 50
  }
}
