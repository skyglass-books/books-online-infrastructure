# Resource: Keycloak Postgres Kubernetes Deployment
resource "kubernetes_deployment_v1" "bank_mysql_deployment" {
  metadata {
    name = "bank-mysql"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "bank-mysql"
      }          
    }
    strategy {
      type = "Recreate"
    }  
    template {
      metadata {
        labels = {
          app = "bank-mysql"
        }
      }
      spec {
        volume {
          name = "bank-mysql-dbcreation-script"
          config_map {
            name = kubernetes_config_map_v1.bank_mysql_config_map.metadata.0.name 
          }
        }        
        container {
          name = "bank-mysql"
          image = "mysql:latest"
          port {
            container_port = 3306
            name = "mysql"
          }
          env {
            name = "MYSQL_ROOT_PASSWORD"
            value = "dbpassword11"
          }
          volume_mount {
            name = "bank-mysql-dbcreation-script"
            mount_path = "/docker-entrypoint-initdb.d"
          }          
        }
      }
    }      
  }
  
}

# Resource: Bank MySQL Horizontal Pod Autoscaler
resource "kubernetes_horizontal_pod_autoscaler_v1" "bank_mysql_hpa" {
  metadata {
    name = "bank-mysql-hpa"
  }
  spec {
    max_replicas = 2
    min_replicas = 1
    scale_target_ref {
      api_version = "apps/v1"
      kind = "Deployment"
      name = kubernetes_deployment_v1.bank_mysql_deployment.metadata[0].name
    }
    target_cpu_utilization_percentage = 60
  }
}

# Resource: Bank MySQL Cluster IP Service
resource "kubernetes_service_v1" "bank_mysql_service" {
  metadata {
    name = "bank-mysql"
  }
  spec {
    selector = {
      app = kubernetes_deployment_v1.bank_mysql_deployment.spec.0.selector.0.match_labels.app 
    }
    port {
      port        = 3306 # Service Port
      #target_port = 3306 # Container Port  # Ignored when we use cluster_ip = "None"
    }
    type = "ClusterIP"
    cluster_ip = "None" # This means we are going to use Pod IP   
  }
}