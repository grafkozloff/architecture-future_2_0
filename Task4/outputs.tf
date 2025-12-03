output "network_id" {
  description = "ID of the created network"
  value       = yandex_vpc_network.main.id
}

output "subnet_id" {
  description = "ID of the main subnet"
  value       = yandex_vpc_subnet.main.id
}

output "postgresql_host" {
  description = "PostgreSQL host"
  value       = yandex_mdb_postgresql_cluster.main.host[0].fqdn
}

output "datahub_public_ip" {
  description = "Public IP address of DataHub server"
  value       = yandex_compute_instance.datahub.network_interface[0].nat_ip_address
}

output "keycloak_public_ip" {
  description = "Public IP address of Keycloak server"
  value       = yandex_compute_instance.keycloak.network_interface[0].nat_ip_address
}

output "dremio_public_ip" {
  description = "Public IP address of Dremio server"
  value       = yandex_compute_instance.dremio.network_interface[0].nat_ip_address
}

output "portal_public_ip" {
  description = "Public IP address of self-service portal"
  value       = yandex_compute_instance.portal.network_interface[0].nat_ip_address
}

output "load_balancer_ip" {
  description = "Load balancer external IP address"
  value       = one(yandex_lb_network_load_balancer.external_lb.listener[*].external_address_spec[*].address)
}

output "medical_service_ip" {
  description = "Internal IP address of medical services"
  value       = yandex_compute_instance.medical.network_interface[0].ip_address
}

output "fintech_service_ip" {
  description = "Internal IP address of fintech services"
  value       = yandex_compute_instance.fintech.network_interface[0].ip_address
}

output "ai_service_ip" {
  description = "Internal IP address of AI services"
  value       = yandex_compute_instance.ai.network_interface[0].ip_address
}

output "bi_server_ip" {
  description = "Internal IP address of BI server"
  value       = yandex_compute_instance.bi.network_interface[0].ip_address
}

output "storage_bucket_name" {
  description = "Name of the created storage bucket"
  value       = yandex_storage_bucket.data_bucket.bucket
}

output "security_group_external_id" {
  description = "ID of external security group"
  value       = yandex_vpc_security_group.external.id
}

output "security_group_internal_id" {
  description = "ID of internal security group"
  value       = yandex_vpc_security_group.internal.id
}

output "kafka_cluster_id" {
  description = "ID of the Kafka cluster"
  value       = yandex_mdb_kafka_cluster.main.id
}

output "kafka_connection_string" {
  description = "Kafka connection string"
  value       = "${yandex_mdb_kafka_cluster.main.id}.mdb.yandexcloud.net:9091"
}