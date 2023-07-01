resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "simple-fanout-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class" =  "nginx"
      "nginx.ingress.kubernetes.io/server-snippet" =  <<EOF
        location ~* "^/actuator" {
          deny all;
          return 403;
        }
      EOF
      # "nginx.ingress.kubernetes.io/proxy-set-header" = <<EOF
      #   Host $host;
      #   X-Real-IP $remote_addr;
      #   X-Forwarded-For $proxy_add_x_forwarded_for;
      #   X-Forwarded-Proto $scheme;
      # EOF      
    }
  }

  spec {
    ingress_class_name = "nginx"

    default_backend {
     
      service {
        name = "keycloak-server"
        port {
          number = 8080
        }
      }
    }     

    rule {
      host = "keycloak.greeta.net"
      http {

        path {
          backend {
            service {
              name = "keycloak-server"
              port {
                number = 8080
              }
            }
          }

          path = "/"
          path_type = "Prefix"
        }
      }
    }

    rule {
      host = "books.greeta.net"
      http {

        path {
          backend {
            service {
              name = "edge-service"
              port {
                number = 9000
              }
            }
          }

          path = "/"
          path_type = "Prefix"
        }
      }
    }
    
  }
}
