
output "public_ec2_ip" {
  value = aws_instance.public_ec2.public_ip
}

output "private_ec2_ip" {
  value = var.create_private_ec2 ? aws_instance.private_ec2[0].private_ip : null
}
