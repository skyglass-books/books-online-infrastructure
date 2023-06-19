resource "kubernetes_deployment" "books_redis" {
  metadata {
    name = "books-redis"
    labels = {
      db = "books-redis"
    }
  }

  spec {
    selector {
      match_labels = {
        db = "books-redis"
      }
    }

    template {
      metadata {
        labels = {
          db = "books-redis"
        }
      }

      spec {
        container {
          name  = "books-redis"
          image = "redis:7.0"

          resources {
            requests {
              cpu    = "100m"
              memory = "50Mi"
            }
            limits {
              cpu    = "200m"
              memory = "100Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "books_redis" {
  metadata {
    name = "books-redis"
    labels = {
      db = "books-redis"
    }
  }

  spec {
    selector = {
      db = "books-redis"
    }

    port {
      protocol = "TCP"
      port     = 6379
      target_port = 6379
    }
  }
}

# Resource: Books Redis Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "books_redis_hpa" {
  metadata {
    name = "books-redis-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.books_redis_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 60
  }
}