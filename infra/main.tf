provider "aws" {
  region = var.region
}

# ---------------------------------------------------------------------
# Data: Availability Zones
# ---------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

# ---------------------------------------------------------------------
# VPC using terraform-aws-modules/vpc/aws
# ---------------------------------------------------------------------
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

# ---------------------------------------------------------------------
# Terraform-managed Key Pair
# ---------------------------------------------------------------------
resource "aws_key_pair" "terraform_key" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

# ---------------------------------------------------------------------
# Bastion Security Group
# ---------------------------------------------------------------------
resource "aws_security_group" "ansible_bastion_sg" {
  vpc_id      = module.vpc.vpc_id
  name        = "bastion-sg"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.cidr_blocks_ingress_bastion
    description = "Allow SSH from my IP to Bastion"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.cidr_blocks_egress
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "bastion-sg"
  }
}

# ---------------------------------------------------------------------
# Bastion Host
# ---------------------------------------------------------------------
resource "aws_instance" "bastion" {
  ami                         = var.ami
  instance_type               = var.instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  key_name                    = aws_key_pair.terraform_key.key_name
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ansible_bastion_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y software-properties-common git vim
              add-apt-repository --yes --update ppa:ansible/ansible
              apt install -y ansible >> /var/log/ansible-install.log 2>&1
              echo "Ansible installed successfully" >> /var/log/ansible-install.log
              git clone https://github.com/thani2808/first-bastion.git /opt/ansible-playbooks
              EOF

  tags = {
    Name = "Bastion"
  }
}

# ---------------------------------------------------------------------
# Private EC2 Security Group
# ---------------------------------------------------------------------
resource "aws_security_group" "private_ec2" {
  vpc_id = module.vpc.vpc_id

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
    Name = "Private-EC2-Security-Group"
  }
}

# ---------------------------------------------------------------------
# Private EC2 Instances
# ---------------------------------------------------------------------
resource "aws_instance" "dev_ec2_private" {
  count                  = length(module.vpc.private_subnets)
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = module.vpc.private_subnets[count.index]
  key_name               = aws_key_pair.terraform_key.key_name
  vpc_security_group_ids = [aws_security_group.private_ec2.id]

  tags = {
    Name = "EC2-${count.index}"
  }

  depends_on = [aws_instance.bastion]

  connection {
    type                = "ssh"
    host                = self.private_ip
    user                = "ubuntu"
    private_key         = file(var.private_key_path)
    bastion_host        = aws_instance.bastion.public_ip
    bastion_user        = "ubuntu"
    bastion_private_key = file(var.private_key_path)
    timeout             = "12m"
  }
}