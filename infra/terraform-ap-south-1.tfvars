region   = "ap-south-1"
vpc_name = "eks-vpc-ap-south-1"
vpc_cidr = "10.0.0.0/16"

azs = ["ap-south-1a"]

public_subnets      = ["10.0.1.0/24"]
public_subnet_names = ["public-subnet-1"]

private_subnets      = ["10.0.101.0/24"]
private_subnet_names = ["private-subnet-1"]

instance_type = "t3.micro"

cidr_blocks_ingress_bastion = ["49.204.140.119/32"]
cidr_blocks_egress          = ["0.0.0.0/0"]