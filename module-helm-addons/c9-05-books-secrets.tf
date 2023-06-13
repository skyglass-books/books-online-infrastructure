resource "kubernetes_secret" "polar_postgres_catalog_credentials" {
  metadata {
    name = "polar-postgres-catalog-credentials"
  }

  data = {
    "spring.datasource.url"      = "jdbc:postgresql://polar-postgres:5432/polardb_catalog"
    "spring.datasource.username" = "user"
    "spring.datasource.password" = "password"
  }
}

resource "kubernetes_secret" "polar_postgres_order_credentials" {
  metadata {
    name = "polar-postgres-order-credentials"
  }

  data = {
    "spring.flyway.url"         = "jdbc:postgresql://polar-postgres:5432/polardb_order"
    "spring.r2dbc.url"          = "r2dbc:postgresql://polar-postgres:5432/polardb_order?ssl=true&sslMode=require"
    "spring.r2dbc.username"     = "user"
    "spring.r2dbc.password"     = "password"
  }
}