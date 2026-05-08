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
  is_arm = can(regex("[a-zA-Z]+\\d+g[a-z]*\\..+", var.instance_type))
  tags = {
    ManagedBy      = "gatewatch"
    GatewatchToken = var.api_token
  }
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_ami" "fck_nat" {
  most_recent = true
  owners      = ["568608671756"]

  filter {
    name   = "name"
    values = ["fck-nat-al2023-hvm-*"]
  }

  filter {
    name   = "architecture"
    values = [local.is_arm ? "arm64" : "x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags   = local.tags
}

resource "aws_network_interface" "nat" {
  description       = "${var.name} static private ENI"
  subnet_id         = var.subnet_id
  security_groups   = [aws_security_group.nat.id]
  source_dest_check = false

  tags = merge({ Name = var.name }, local.tags)
}

resource "aws_route" "private" {
  for_each = { for idx, id in var.private_route_table_ids : "rt-${idx}" => id }

  route_table_id         = each.value
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = aws_network_interface.nat.id
}

resource "aws_launch_template" "nat" {
  name          = "${var.name}-nat"
  image_id      = data.aws_ami.fck_nat.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.gatewatch.name
  }

  network_interfaces {
    description                 = "${var.name} ephemeral public ENI"
    subnet_id                   = var.subnet_id
    associate_public_ip_address = true
    security_groups             = [aws_security_group.nat.id]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    eni_id          = aws_network_interface.nat.id
    eip_id          = aws_eip.nat.id
    api_url         = var.api_url
    api_token       = var.api_token
    releases_bucket = var.releases_bucket
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge({ Name = var.name }, local.tags)
  }

  tags = local.tags
}

resource "aws_autoscaling_group" "nat" {
  name                = "${var.name}-nat"
  max_size            = 1
  min_size            = 1
  desired_capacity    = 1
  health_check_type   = "EC2"
  vpc_zone_identifier = [var.subnet_id]

  launch_template {
    id      = aws_launch_template.nat.id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = local.tags

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = false
    }
  }

  timeouts {
    delete = "15m"
  }
}
