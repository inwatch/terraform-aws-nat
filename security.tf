resource "aws_security_group" "nat" {
  name        = "${var.name}-nat"
  description = "NAT instance - outbound only, no inbound (SSM access only)"
  vpc_id      = var.vpc_id
  tags        = local.tags
}

resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.nat.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Outbound only - required for NAT"
  tags              = local.tags
}
