terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  tags = {
    ManagedBy      = "gatewatch"
    GatewatchToken = var.api_token
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = local.tags
}

module "fck_nat" {
  source  = "RaJiska/fck-nat/aws"
  version = "~> 1.3.0"

  name          = var.name
  vpc_id        = var.vpc_id
  subnet_id     = var.subnet_id
  instance_type = var.instance_type
  ha_mode       = true

  eip_allocation_ids            = [aws_eip.nat.id]
  iam_instance_profile_name     = aws_iam_instance_profile.gatewatch.name
  use_default_security_group    = false
  additional_security_group_ids = [aws_security_group.nat.id]

  update_route_tables = true
  route_tables_ids    = { for idx, id in var.private_route_table_ids : "rt-${idx}" => id }

  extra_user_data = templatefile("${path.module}/user_data.sh", {
    api_url         = var.api_url
    api_token       = var.api_token
    releases_bucket = var.releases_bucket
  })

  tags = local.tags
}
