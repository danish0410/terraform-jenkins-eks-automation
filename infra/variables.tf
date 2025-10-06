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
  description = "List of availability zones (e.g. ap-south-1a, ap-south-1b)"
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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "cidr_blocks_ingress_bastion" {
  description = "Allowed CIDR blocks for Bastion ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cidr_blocks_egress" {
  description = "Allowed CIDR blocks for egress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}