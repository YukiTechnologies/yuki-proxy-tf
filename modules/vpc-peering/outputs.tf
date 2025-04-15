output "private_zone_id" {
  description = "The ID of the private Route 53 hosted zone"
  value       = aws_route53_zone.private.id
}