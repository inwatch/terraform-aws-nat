output "nat_elastic_ip" {
  description = "Fixed public IP of the NAT instance"
  value       = aws_eip.nat.public_ip
}

output "nat_asg_name" {
  description = "Name of the Auto Scaling Group managing the NAT instance"
  value       = aws_autoscaling_group.nat.name
}

output "nat_iam_role_arn" {
  description = "ARN of the IAM role attached to the NAT instance"
  value       = aws_iam_role.gatewatch.arn
}

output "nat_security_group_id" {
  description = "ID of the NAT instance security group"
  value       = aws_security_group.nat.id
}
