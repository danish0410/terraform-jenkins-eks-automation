variable "region" {
  description = "AWS Region"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "vpc_name" {
  description = "The name tag for the VPC"
  type        = string
}

variable "web_sub_cidr" {
  description = "CIDR for public subnet"
  type        = string
}

variable "web_availability_zone1a" {
  description = "AZ for public subnet"
  type        = string
}

variable "web_sub_name" {
  description = "The name tag for the web subnet"
  type        = string
}

variable "app_sub_cidr_1a" {
  type        = string
  description = "CIDR for private subnet 1a"
}

variable "app_availability_zone1a" {
  type        = string
  description = "AZ for private subnet 1a"
}

variable "app_sub_name_1a" {
  type        = string
  description = "Name tag for app subnet 1a"
}

variable "app_sub_cidr_1b" {
  type        = string
  description = "CIDR for private subnet 1b"
}

variable "app_availability_zone1b" {
  type        = string
  description = "AZ for private subnet 1b"
}

variable "app_sub_name_1b" {
  type        = string
  description = "Name tag for app subnet 1b"
}

variable "db_sub_cidr" {
  type        = string
  description = "CIDR for DB subnet"
}

variable "db_availability_zone1a" {
  type        = string
  description = "AZ for DB subnet"
}

variable "db_sub_name" {
  type        = string
  description = "Name tag for DB subnet"
}

variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "eks_nodegroup_name" {
  type        = string
  description = "EKS node group name"
}

variable "desired_capacity" {
  type        = number
  description = "Desired number of nodes"
}

variable "min_size" {
  type        = number
  description = "Min number of nodes"
}

variable "max_size" {
  type        = number
  description = "Max number of nodes"
}

variable "instance_type" {
  type        = string
  description = "Instance type for nodes"
}

variable "aws_ami" {
  type        = string
  description = "AMI ID for Bastion"
}

variable "bastion_instance_type" {
  type        = string
  description = "Bastion instance type"
}

variable "public_key_path" {
  type        = string
  description = "Path to SSH public key"
}

variable "env" {
  type        = string
  description = "Environment name (e.g., dev/staging/prod)"
}

variable "my_igw_name" {
  type        = string
  description = "Internet Gateway name"
}

variable "pub_route_name" {
  type        = string
  description = "Public route table name"
}

variable "pri_route_name" {
  type        = string
  description = "Private route table name"
}

variable "vpc_route_cidr" {
  type        = string
  description = "Route table CIDR block (e.g., 0.0.0.0/0)"
}

variable "log_bucket_prefix" {
  type        = string
  description = "S3 bucket log prefix"
}