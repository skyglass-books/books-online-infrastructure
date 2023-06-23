# Resource: Config Map
 data "kubectl_file_documents" "keyloak_server_config_yaml" {
  content = file("${path.module}/keycloak-server-config.yml")
}

resource "kubectl_manifest" "keycloak_server_configmap" {
    for_each  = data.kubectl_file_documents.keyloak_server_config_yaml.manifests
    yaml_body = each.value
}