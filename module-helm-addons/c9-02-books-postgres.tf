resource "kubernetes_config_map_v1" "polar_postgres_config" {
  metadata {
    name = "polar-postgres-config"

    labels = {
      db = "polar-postgres"
    }
  }

  data = {
    "init.sql" = <<EOF
      CREATE DATABASE polardb_catalog;
      CREATE DATABASE polardb_order;
    EOF
  }
}

resource "kubernetes_deployment_v1" "polar_postgres_deployment" {
  metadata {
    name = "polar-postgres"

    labels = {
      db = "polar-postgres"
    }
  }

  spec {
    selector {
      match_labels = {
        db = "polar-postgres"
      }
    }

    template {
      metadata {
        labels = {
          db = "polar-postgres"
        }
      }

      spec {
        container {
          name  = "polar-postgres"
          image = "postgres:14.4"

          env {
            name  = "POSTGRES_USER"
            value = "user"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }

          resources {
            requests = {
              cpu    = "100m"
              memory = "60Mi"
            }

            limits = {
              cpu    = "200m"
              memory = "120Mi"
            }
          }

          volume_mount {
            mount_path = "/docker-entrypoint-initdb.d"
            name       = "polar-postgres-config-volume"
          }
        }

        volume {
          name = "polar-postgres-config-volume"

          config_map {
            name = kubernetes_config_map_v1.polar_postgres_config.metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "polar_postgres" {
  metadata {
    name = "polar-postgres"

    labels = {
      db = "polar-postgres"
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      db = "polar-postgres"
    }

    port {
      protocol    = "TCP"
      port        = 5432
      target_port = 5432
    }
  }
}

# Resource: Polar Postgres Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "polar_postgres_hpa" {
  metadata {
    name = "polar-postgres-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.polar_postgres_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 60
  }
}