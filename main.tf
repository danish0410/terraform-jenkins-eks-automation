# ------------------------------------------
# Complete Terraform Workflow for EKS Setup
# ------------------------------------------

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.region
}

# ------------------------------------------
# Automatically Get Your Public IP
# ------------------------------------------
#data "http" "my_ip" {
#  url = "https://api.ipify.org"
#}

#locals {
#  my_ip_cidr = "${chomp(data.http.my_ip.body)}/32"
#}

# ------------------------------------------
# VPC
# ------------------------------------------
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# ------------------------------------------
# Subnets
# ------------------------------------------
resource "aws_subnet" "public_subnet_1a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.web_sub_cidr
  availability_zone       = var.web_availability_zone1a
  map_public_ip_on_launch = true

  tags = {
    Name = var.web_sub_name
  }
}

resource "aws_subnet" "private_1a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_sub_cidr_1a
  availability_zone = var.app_availability_zone1a

  tags = {
    Name = var.app_sub_name_1a
  }
}

resource "aws_subnet" "private_1b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.app_sub_cidr_1b
  availability_zone = var.app_availability_zone1b

  tags = {
    Name = var.app_sub_name_1b
  }
}

resource "aws_subnet" "db_subnet" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.db_sub_cidr
  availability_zone = var.db_availability_zone1a

  tags = {
    Name = var.db_sub_name
  }
}

# ------------------------------------------
# Internet Gateway & Routing
# ------------------------------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.my_igw_name
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = var.vpc_route_cidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = var.pub_route_name
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet_1a.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------------------------------
# NAT Gateway Setup
# ------------------------------------------
resource "aws_eip" "nat_eip" {
  tags = {
    Name = "nat-eip"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1a.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-gw"
  }
}

resource "aws_route_table" "private_rt_1a" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.pri_route_name
  }
}

resource "aws_route_table" "private_rt_1b" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.pri_route_name}-1b"
  }
}

resource "aws_route" "private_nat_route_1a" {
  route_table_id         = aws_route_table.private_rt_1a.id
  destination_cidr_block = var.vpc_route_cidr
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route" "private_nat_route_1b" {
  route_table_id         = aws_route_table.private_rt_1b.id
  destination_cidr_block = var.vpc_route_cidr
  nat_gateway_id         = aws_nat_gateway.nat_gw.id
}

resource "aws_route_table_association" "private_1a" {
  subnet_id      = aws_subnet.private_1a.id
  route_table_id = aws_route_table.private_rt_1a.id
}

resource "aws_route_table_association" "private_1b" {
  subnet_id      = aws_subnet.private_1b.id
  route_table_id = aws_route_table.private_rt_1b.id
}

resource "aws_route_table_association" "private_db" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.private_rt_1a.id
}

# ------------------------------------------
# EC2 Bastion Host
# ------------------------------------------
resource "aws_key_pair" "id_rsa" {
  key_name   = "id_rsa"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

resource "aws_instance" "bastion" {
  ami                         = var.aws_ami
  instance_type               = var.bastion_instance_type
  subnet_id                   = aws_subnet.public_subnet_1a.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.id_rsa.key_name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "${var.env}-bastion-host"
  }
}

# ------------------------------------------
# IAM Role for EKS Cluster
# ------------------------------------------

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.env}-eks-cluster-role"

  assume_role_policy = data.aws_iam_policy_document.eks_assume_role.json

  tags = {
    Name = "${var.env}-eks-cluster-role"
  }
}

data "aws_iam_policy_document" "eks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# ------------------------------------------
# IAM Role for EKS Worker Nodes
# ------------------------------------------

resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.env}-eks-node-group-role"

  assume_role_policy = data.aws_iam_policy_document.eks_node_assume_role.json

  tags = {
    Name = "${var.env}-eks-node-group-role"
  }
}

data "aws_iam_policy_document" "eks_node_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# ------------------------------------------
# EKS Cluster
# ------------------------------------------

resource "aws_eks_cluster" "this" {
  name     = "${var.env}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.29"

  vpc_config {
    subnet_ids = [
      aws_subnet.private_1a.id,
      aws_subnet.private_1b.id
    ]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# ------------------------------------------
# EKS Node Group
# ------------------------------------------

resource "aws_eks_node_group" "private_nodes" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${var.env}-private-nodes"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids = [
    aws_subnet.private_1a.id,
    aws_subnet.private_1b.id
  ]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_worker_node_AmazonEC2ContainerRegistryReadOnly
  ]

  tags = {
    Name = "${var.env}-private-nodes"
  }
}

# ------------------------------------------
# VPC Endpoints for S3 and DynamoDB
# ------------------------------------------

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_rt_1a.id,
    aws_route_table.private_rt_1b.id
  ]

  tags = {
    Name = "${var.env}-s3-endpoint"
  }
}

resource "aws_vpc_endpoint" "dynamodb" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.region}.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.private_rt_1a.id,
    aws_route_table.private_rt_1b.id
  ]

  tags = {
    Name = "${var.env}-dynamodb-endpoint"
  }
}
