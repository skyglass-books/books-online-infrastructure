resource "kubernetes_secret_v1" "polar_postgres_catalog_credentials" {
  metadata {
    name = "polar-postgres-catalog-credentials"
  }

  data = {
    "spring.datasource.url"      = "jdbc:postgresql://polar-postgres:5432/polardb_catalog"
    "spring.datasource.username" = "user"
    "spring.datasource.password" = "password"
  }
}

resource "kubernetes_secret_v1" "polar_postgres_order_credentials" {
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

resource "kubernetes_secret_v1" "polar_redis_credentials" {
  metadata {
    name = "polar-redis-credentials"
  }

  data = {
    "spring.redis.host"     = "polar-redis.default.svc.cluster.local"
    "spring.redis.port"     = "6379"
    "spring.redis.username" = "default"
  }
}

resource "kubernetes_secret_v1" "polar_rabbitmq_credentials" {
  metadata {
    name = "polar-rabbitmq-credentials"
  }  

  data = {
    "spring.rabbitmq.host"     = "polar-rabbitmq"
    "spring.rabbitmq.port"     = "5672"
    "spring.rabbitmq.username" = "user"
    "spring.rabbitmq.password" = "password"
  }
}

resource "kubernetes_secret_v1" "polar_keycloak_client_credentials" {
  metadata {
    name = "keycloak-server-client-credentials"
  }

  data = {
    "spring.security.oauth2.client.registration.keycloak.client-secret" = "1b1b19599c2264fd218c"
  }
}

resource "kubernetes_secret_v1" "keycloak_issuer_secret" {
  metadata {
    name = "keycloak-issuer-secret"
  }

  data = {
    "spring.keycloak.server-url" = "http://keycloak-server:8080"
  }
}