region        = "ap-south-1"
vpc_name      = "ansible-vpc"
vpc_cidr      = "10.0.0.0/16"
ami           = "ami-00305d2fa3c93abfc"
instance_type = "t2.micro"

azs = ["ap-south-1a", "ap-south-1b"]

public_subnets      = ["10.0.1.0/28"]
public_subnet_names = ["public-ap-south-1a"]

private_subnets      = ["10.0.3.0/28"]
private_subnet_names = ["private-ap-south-1a"]

cidr_blocks_ingress_bastion = ["49.205.81.112/32"]
cidr_blocks_egress          = ["0.0.0.0/0"]