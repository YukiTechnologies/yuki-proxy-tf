output "endpoint_url" {
  value = aws_elasticache_replication_group.valkey_cluster.configuration_endpoint_address
}