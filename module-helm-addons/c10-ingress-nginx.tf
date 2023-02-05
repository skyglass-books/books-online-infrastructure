resource "kubernetes_ingress_v1" "ingress" {
  wait_for_load_balancer = true
  metadata {
    name = "simple-fanout-ingress"
    annotations = {
      "nginx.ingress.kubernetes.io/rewrite-target" = "/"
      "kubernetes.io/ingress.class" =  "nginx"     
    }
  }

  spec {

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
      host = "bank-api.greeta.net"
      http {

        path {
          backend {
            service {
              name = "bank-api"
              port {
                number = 8081
              }
            }
          }

          path = "/"
          path_type = "Prefix"
        }
      }
    } 

    rule {
      host = "bank.greeta.net"
      http {

        path {
          backend {
            service {
              name = "bank-ui"
              port {
                number = 4200
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
