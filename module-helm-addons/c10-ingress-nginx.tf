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
    }
  }

  spec {
    ingress_class_name = "nginx"

    default_backend {
     
      service {
        name = "polar-keycloak"
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
              name = "polar-keycloak"
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
      host = "books-api.greeta.net"
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

    rule {
      host = "books.greeta.net"
      http {

        path {
          backend {
            service {
              name = "books-ui"
              port {
                number = 9004
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
