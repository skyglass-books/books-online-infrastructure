# Install Keycloak Server using Kubernetes Deployment
# Resource: Keycloak Kubernetes Deployment
resource "kubernetes_deployment_v1" "bank_api_deployment" {
  depends_on = [kubernetes_deployment_v1.bank_mysql_deployment]
  metadata {
    name = "bank-api"
    labels = {
      app = "bank-api"
    }
  }
 
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "bank-api"
      }
    }
    template {
      metadata {
        labels = {
          app = "bank-api"
        }
      }
      spec {
        container {
          image = "skyglass/bank-online-api:0.0.1-SNAPSHOT"
          name  = "bank-api"
          image_pull_policy = "Always"
          port {
            container_port = 8081
          }
          env {
            name = "SPRING_DATASOURCE_URL"
            value = "jdbc:mysql://bank-mysql:3306/eazybank"
          }
          env {
            name = "SPRING_DATASOURCE_PASSWORD"
            value = "dbpassword11"
          }
          env {
            name = "SPRING_SQL_INIT_MODE"
            value = "NEVER"
          }                                                                                                          
        }
      }
    }
  }
}

# Resource: Keycloak Server Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "bank_api_hpa" {
  metadata {
    name = "bank-api-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.bank_api_deployment.metadata[0].name 
    }
    target_cpu_utilization_percentage = 50
  }
}

resource "kubernetes_service_v1" "bank_api_service" {
  metadata {
    name = "bank-api"
  }
  spec {
    selector = {
      app = "bank-api"
    }
    port {
      port = 8081
    }
  }
}
