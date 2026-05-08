output "nat_instance_id" {
  description = "ID de l'instance EC2 active (change si l'ASG remplace l'instance)"
  value       = module.fck_nat.instance_id
}

output "nat_elastic_ip" {
  description = "IP publique fixe de l'instance NAT"
  value       = aws_eip.nat.public_ip
}

output "nat_asg_name" {
  description = "Nom de l'Auto Scaling Group gérant l'instance NAT"
  value       = module.fck_nat.asg_name
}

output "nat_iam_role_arn" {
  description = "ARN du rôle IAM attaché à l'instance NAT"
  value       = aws_iam_role.gatewatch.arn
}

output "nat_security_group_id" {
  description = "ID du security group de l'instance NAT"
  value       = aws_security_group.nat.id
}
