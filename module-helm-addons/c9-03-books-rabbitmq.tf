resource "kubernetes_config_map_v1" "polar_rabbitmq_config" {
  metadata {
    name = "polar-rabbitmq-config"
    labels = {
      db = "polar-rabbitmq"
    }
  }

  data = {
    "rabbitmq.conf" = <<EOF
      default_user = user
      default_pass = password
      vm_memory_high_watermark.relative = 1.0
    EOF
  }
}

resource "kubernetes_deployment_v1" "polar_rabbitmq_deployment" {
  metadata {
    name = "polar-rabbitmq"
    labels = {
      db = "polar-rabbitmq"
    }
  }

  spec {
    selector {
      match_labels = {
        db = "polar-rabbitmq"
      }
    }

    template {
      metadata {
        labels = {
          db = "polar-rabbitmq"
        }
      }

      spec {
        container {
          name  = "polar-rabbitmq"
          image = "rabbitmq:3.10-management"         

          resources {
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "150Mi"
            }
          }

          volume_mount {
            mount_path = "/etc/rabbitmq"
            name       = "polar-rabbitmq-config-volume"
          }
        }

        volume {
          name = "polar-rabbitmq-config-volume"

          config_map {
            name = kubernetes_config_map_v1.polar_rabbitmq_config.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "polar_rabbitmq" {
  metadata {
    name = "polar-rabbitmq"
    labels = {
      db = "polar-rabbitmq"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      db = "polar-rabbitmq"
    }

    port {
      name       = "amqp"
      protocol   = "TCP"
      port       = 5672
      target_port = 5672
    }

    port {
      name       = "management"
      protocol   = "TCP"
      port       = 15672
      target_port = 15672
    }
  }
}

# Resource: Polar RabbitMQ Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "polar_rabbitmq_hpa" {
  metadata {
    name = "polar-rabbitmq-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.polar_rabbitmq_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 60
  }
}