variable "region" {
  description = "AWS region"
  type        = string
}

variable "vpc_name" {
  description = "VPC name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnets" {
  description = "List of public subnet CIDRs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs"
  type        = list(string)
}

variable "public_subnet_names" {
  description = "Names of public subnets"
  type        = list(string)
}

variable "private_subnet_names" {
  description = "Names of private subnets"
  type        = list(string)
}

variable "ami" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name for the key pair"
  type        = string
}

variable "public_key_path" {
  description = "Path to the public key file"
  type        = string
}

variable "private_key_path" {
  description = "Path to the private key file"
  type        = string
}

variable "cidr_blocks_ingress_bastion" {
  description = "Allowed CIDR blocks for Bastion ingress"
  type        = list(string)
}

variable "cidr_blocks_egress" {
  description = "Allowed CIDR blocks for egress"
  type        = list(string)
}