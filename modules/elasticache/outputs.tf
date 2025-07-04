output "endpoint_url" {
  value = aws_elasticache_replication_group.valkey_cluster.configuration_endpoint_address
}

output "security_group_id" {
  value = aws_elasticache_replication_group.valkey_cluster.security_group_ids[0]
}