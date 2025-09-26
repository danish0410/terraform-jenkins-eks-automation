region   = "ap-south-1"
vpc_name = "eks-vpc-ap-south-1"
vpc_cidr = "10.0.0.0/16"

azs = ["ap-south-1a", "ap-south-1b"]

public_subnets      = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_names = ["public-subnet-1", "public-subnet-2"]

private_subnets      = ["10.0.101.0/24", "10.0.102.0/24"]
private_subnet_names = ["private-subnet-1", "private-subnet-2"]

ami           = "ami-0c1a7f89451184c8b"
instance_type = "t3.micro"

key_name         = "terraform-key-ap-south-1"
public_key_path  = "/home/thani/.ssh/id_rsa.pub"
private_key_path = "/home/thani/.ssh/id_rsa"

cidr_blocks_ingress_bastion = ["49.204.129.43/32"]
cidr_blocks_egress          = ["0.0.0.0/0"]