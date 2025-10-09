provider "aws" {
  region = var.region
}

# -------------------------
# TLS key generation (ed25519)
# -------------------------
resource "tls_private_key" "dev_servme_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "${var.region}-dev-servme-key"
  public_key = tls_private_key.dev_servme_key.public_key_openssh
}

# Persist private key locally (secure it after apply)
resource "local_file" "private_key" {
  content         = tls_private_key.dev_servme_key.private_key_pem
  filename        = "${path.module}/dev_servme-${var.region}.pem"
  file_permission = "0400"
}

# -------------------------
# Dynamic AMI lookup (Ubuntu LTS example)
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
# VPC module
# -------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.19.0"

  name = var.vpc_name
  cidr = var.vpc_cidr

  azs                  = var.azs
  private_subnets      = var.private_subnets
  private_subnet_names = var.private_subnet_names
  public_subnets       = var.public_subnets
  public_subnet_names  = var.public_subnet_names

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    subnet                   = "public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    subnet                            = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# -------------------------
# dev_servme (former bastion) SG - public
# -------------------------
resource "aws_security_group" "dev_servme_sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "dev_servme-sg-${var.region}"
  description = "Allow SSH access to dev_servme (public)"

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
    Name = "dev_servme-sg-${var.region}"
  }
}

# -------------------------
# Private EC2 SG (only allow SSH from dev_servme SG)
# -------------------------
resource "aws_security_group" "private_ec2" {
  vpc_id = module.vpc.vpc_id
  name   = "private-ec2-sg-${var.region}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.dev_servme_sg.id]
    description     = "Allow SSH from dev_servme"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks_egress
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "Private-EC2-Security-Group-${var.region}"
  }
}

# -------------------------
# Launch Template for dev_servme (public instances)
# user_data is loaded from file: dev_servme_userdata.sh
# -------------------------
resource "aws_launch_template" "dev_servme_lt" {
  name_prefix   = "dev-servme-lt-${var.region}-"
  image_id      = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.dev_servme_sg.id]
  }

  user_data = base64encode(file("${path.module}/dev_servme_userdata.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "dev_servme-instance-${var.region}"
    }
  }
}

# -------------------------
# Launch Template for private EC2 instances (no public IP)
# uses same AMI and key, but different SG & no public IP
# -------------------------
resource "aws_launch_template" "private_lt" {
  name_prefix   = "private-ec2-lt-${var.region}-"
  image_id      = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.private_ec2.id]
  }

  # keep a simple userdata or reuse same script if wanted
  user_data = base64encode(file("${path.module}/dev_servme_userdata.sh"))

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "private-ec2-instance-${var.region}"
    }
  }
}

# -------------------------
# AutoScaling Group(s) for dev_servme (one ASG per public subnet)
# Each ASG will run exactly 1 instance in that subnet (AZ)
# -------------------------
resource "aws_autoscaling_group" "dev_servme_asg" {
  count            = length(module.vpc.public_subnets)
  name             = "dev-servme-asg-${var.region}-${count.index}"
  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier = [module.vpc.public_subnets[count.index]]
  health_check_type   = "EC2"
  force_delete        = true

  launch_template {
    id      = aws_launch_template.dev_servme_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "dev-servme-asg-${var.region}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_launch_template.dev_servme_lt,
    aws_key_pair.terraform_key
  ]
}

# -------------------------
# AutoScaling Group(s) for private EC2 (one ASG per private subnet)
# Each private ASG runs exactly 1 instance (for private hosts)
# -------------------------
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