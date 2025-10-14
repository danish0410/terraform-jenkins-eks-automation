terraform {
  required_version = ">= 1.5.0"

  backend "s3" {} # Leave empty, details will come from backend-ap-south-1.hcl

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.4"
    }
  }
}

provider "aws" {
  region = var.region
}

# -------------------------
# TLS key generation (ed25519)
# -------------------------
resource "tls_private_key" "dev_classic_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "${var.region}-dev-classic-key"
  public_key = tls_private_key.dev_classic_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.dev_classic_key.private_key_pem
  filename        = "${path.module}/dev_classic-${var.region}.pem"
  file_permission = "0400"
}

# -------------------------
# Dynamic AMI lookup (Ubuntu LTS)
# -------------------------
data "aws_ami" "ubuntu_latest" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# -------------------------
# Subnet splitting logic
# -------------------------
locals {
  az_count = length(var.azs)

  newbits = (
    local.az_count <= 1 ? 0 :
    local.az_count <= 2 ? 1 :
    local.az_count <= 4 ? 2 :
    local.az_count <= 8 ? 3 :
    local.az_count <= 16 ? 4 : 5
  )

  # Automatically build public subnets if only one CIDR provided
  public_subnets_final = (
    length(var.public_subnets) == local.az_count ? var.public_subnets :
    length(var.public_subnets) == 1 ? [
      for i in range(local.az_count) : cidrsubnet(var.public_subnets[0], local.newbits, i)
    ] : var.public_subnets
  )

  # Automatically build private subnets if only one CIDR provided
  private_subnets_final = (
    length(var.private_subnets) == local.az_count ? var.private_subnets :
    length(var.private_subnets) == 1 ? [
      for i in range(local.az_count) : cidrsubnet(var.private_subnets[0], local.newbits, i)
    ] : var.private_subnets
  )

  # Auto-generate subnet names
  public_subnet_names_final = (
    length(var.public_subnet_names) == local.az_count ? var.public_subnet_names :
    length(var.public_subnet_names) == 1 ?
    [for i in range(local.az_count) : "${var.public_subnet_names[0]}-${i + 1}"] :
    var.public_subnet_names
  )

  private_subnet_names_final = (
    length(var.private_subnet_names) == local.az_count ? var.private_subnet_names :
    length(var.private_subnet_names) == 1 ?
    [for i in range(local.az_count) : "${var.private_subnet_names[0]}-${i + 1}"] :
    var.private_subnet_names
  )
}

# -------------------------
# VPC Module
# -------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                  = var.azs
  private_subnets      = local.private_subnets_final
  private_subnet_names = local.private_subnet_names_final
  public_subnets       = local.public_subnets_final
  public_subnet_names  = local.public_subnet_names_final

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    subnet = "public"
  }

  private_subnet_tags = {
    subnet = "private"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# -------------------------
# Security Groups
# -------------------------
resource "aws_security_group" "dev_classic_sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "dev_classic-sg-${var.region}"
  description = "Allow SSH access to dev_classic (public)"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress_bastion
    description = "Allow SSH from allowed IPs"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks_egress
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "dev_classic-sg-${var.region}"
  }
}

resource "aws_security_group" "private_ec2" {
  vpc_id = module.vpc.vpc_id
  name   = "private-ec2-sg-${var.region}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.dev_classic_sg.id]
    description     = "Allow SSH from dev_classic"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks_egress
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "private-ec2-sg-${var.region}"
  }
}

# -------------------------
# Launch Templates
# -------------------------
resource "aws_launch_template" "dev_classic_lt" {
  name_prefix   = "dev-classic-lt-${var.region}-"
  image_id      = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.dev_classic_sg.id]
  }

  user_data = base64encode(file("${path.module}/dev_classic_userdata.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "dev_classic-instance-${var.region}"
    }
  }
}

resource "aws_launch_template" "private_lt" {
  name_prefix   = "private-ec2-lt-${var.region}-"
  image_id      = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.private_ec2.id]
  }

  user_data = base64encode(file("${path.module}/dev_classic_userdata.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "private-ec2-instance-${var.region}"
    }
  }
}

# -------------------------
# Auto Scaling Groups
# -------------------------
resource "aws_autoscaling_group" "dev_classic_asg" {
  count            = length(module.vpc.public_subnets)
  name             = "dev-classic-asg-${var.region}-${count.index}"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [module.vpc.public_subnets[count.index]]
  health_check_type   = "EC2"
  force_delete        = true

  launch_template {
    id      = aws_launch_template.dev_classic_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dev-classic-asg-${var.region}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_launch_template.dev_classic_lt,
    aws_key_pair.terraform_key
  ]
}

resource "aws_autoscaling_group" "private_asg" {
  count            = length(module.vpc.private_subnets)
  name             = "private-asg-${var.region}-${count.index}"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [module.vpc.private_subnets[count.index]]
  health_check_type   = "EC2"
  force_delete        = true

  launch_template {
    id      = aws_launch_template.private_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "private-asg-${var.region}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_launch_template.private_lt,
    aws_key_pair.terraform_key
  ]
}