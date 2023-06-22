resource "kubernetes_deployment_v1" "polar_redis_deployment" {
  metadata {
    name = "polar-redis"
    labels = {
      db = "polar-redis"
    }
  }

  spec {
    selector {
      match_labels = {
        db = "polar-redis"
      }
    }

    template {
      metadata {
        labels = {
          db = "polar-redis"
        }
      }

      spec {
        container {
          name  = "polar-redis"
          image = "redis:7.0"

          resources {
            requests = {
              cpu    = "100m"
              memory = "50Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "100Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "polar_redis" {
  metadata {
    name = "polar-redis"
    labels = {
      db = "polar-redis"
    }
  }

  spec {
    selector = {
      db = "polar-redis"
    }

    port {
      protocol = "TCP"
      port     = 6379
      target_port = 6379
    }
  }
}

# Resource: Polar Redis Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "polar_redis_hpa" {
  metadata {
    name = "polar-redis-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.polar_redis_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 60
  }
}