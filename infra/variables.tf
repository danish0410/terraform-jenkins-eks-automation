# --- Module and Provider Versions ---
#variable "aws_provider_version" {
#  description = "Version of AWS provider"
#  type        = string
#  default     = "~> 5.0"
#}

#variable "tls_provider_version" {
#  description = "Version of TLS provider"
#  type        = string
#  default     = "~> 4.0"
#}

#variable "local_provider_version" {
#  description = "Version of Local provider"
#  type        = string
#  default     = "~> 2.5"
#}

#variable "vpc_module_version" {
#  description = "Version of terraform-aws-modules/vpc/aws"
#  type        = string
#  default     = "5.19.0"
#}

# --- Environment Settings ---
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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "cidr_blocks_ingress_bastion" {
  description = "Allowed CIDR blocks for bastion ingress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cidr_blocks_egress" {
  description = "Allowed CIDR blocks for egress"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}