provider "aws" {
  region = var.region
}

# -------------------------
# TLS key generation (ed25519)
# -------------------------
resource "tls_private_key" "bastion_key" {
  algorithm = "ED25519"
}

resource "aws_key_pair" "terraform_key" {
  key_name   = "${var.region}-bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

# Persist private key locally (secure it after apply)
resource "local_file" "private_key" {
  content         = tls_private_key.bastion_key.private_key_pem
  filename        = "${path.module}/bastion-${var.region}.pem"
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
# Bastion SG
# -------------------------
resource "aws_security_group" "ansible_bastion_sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "bastion-sg-${var.region}"
  description = "Allow SSH access to bastion"

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
    Name = "bastion-sg-${var.region}"
  }
}

# -------------------------
# Private EC2 SG (only allow SSH from bastion SG)
# -------------------------
resource "aws_security_group" "private_ec2" {
  vpc_id = module.vpc.vpc_id
  name   = "private-ec2-sg-${var.region}"

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.ansible_bastion_sg.id]
    description     = "Allow SSH from Bastion"
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
# Launch Template for Bastion
# -------------------------
resource "aws_launch_template" "bastion_lt" {
  name_prefix   = "bastion-lt-${var.region}-"
  image_id      = data.aws_ami.ubuntu_latest.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.terraform_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ansible_bastion_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y software-properties-common git vim
              add-apt-repository --yes --update ppa:ansible/ansible
              apt-get update -y
              apt install -y ansible >> /var/log/ansible-install.log 2>&1
              echo "Ansible installed successfully" >> /var/log/ansible-install.log
              git clone https://github.com/thani2808/first-bastion.git /opt/ansible-playbooks || true
              EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Bastion-ASG-${var.region}"
    }
  }
}

# -------------------------
# AutoScaling Group (Bastion)
# -------------------------
resource "aws_autoscaling_group" "bastion_asg" {
  name             = "bastion-asg-${var.region}"
  desired_capacity = 2
  max_size         = 2
  min_size         = 2

  vpc_zone_identifier = module.vpc.public_subnets
  health_check_type   = "EC2"
  force_delete        = true

  launch_template {
    id      = aws_launch_template.bastion_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "Bastion-ASG-${var.region}"
    propagate_at_launch = true
  }

  depends_on = [
    aws_launch_template.bastion_lt,
    aws_key_pair.terraform_key
  ]
}

# -------------------------
# Private EC2 Instances (one per private subnet)
# -------------------------
resource "aws_instance" "dev_ec2_private" {
  count                  = length(module.vpc.private_subnets)
  ami                    = data.aws_ami.ubuntu_latest.id
  instance_type          = var.instance_type
  subnet_id              = module.vpc.private_subnets[count.index]
  key_name               = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.private_ec2.id]

  tags = {
    Name = "EC2-${var.region}-${count.index}"
  }

  depends_on = [aws_autoscaling_group.bastion_asg]
}