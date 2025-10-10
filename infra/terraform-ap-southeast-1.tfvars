region   = "ap-southeast-1"
vpc_name = "eks-vpc-ap-southeast-1"
vpc_cidr = "10.1.0.0/16"

azs = ["ap-southeast-1a"]

public_subnets      = ["10.1.1.0/24"]
public_subnet_names = ["public-subnet-1"]

private_subnets      = ["10.1.101.0/24"]
private_subnet_names = ["private-subnet-1"]

instance_type = "t3.micro"

cidr_blocks_ingress_bastion = ["49.205.83.63/32"]
cidr_blocks_egress          = ["0.0.0.0/0"]