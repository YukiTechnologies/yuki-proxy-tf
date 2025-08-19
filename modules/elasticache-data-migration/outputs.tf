output "instance_id" {
  value = aws_instance.shake_runner.id
}

output "security_group_id" {
  value = aws_security_group.shake_sg.id
}
