variable "region" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "ami" {}
variable "key_name" {}
variable "instance_type" {}

variable "azs" {
  type = list(string)
}

variable "public_subnets" {
  type = list(string)
}
variable "public_subnet_names" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}
variable "private_subnet_names" {
  type = list(string)
}

variable "cidr_blocks_ingress_bastion" {
  type    = list(string)
  default = ["49.205.81.112/32"] # Example IP
}

variable "cidr_blocks_egress" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}