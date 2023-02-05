 # Resource: Config Map
 resource "kubernetes_config_map_v1" "bank_mysql_config_map" {
   metadata {
     name = "bank-mysql-dbcreation-script"
   }
   data = {
    "bank-db.sql" = "${file("${path.module}/bank-db.sql")}"
   }
 } 