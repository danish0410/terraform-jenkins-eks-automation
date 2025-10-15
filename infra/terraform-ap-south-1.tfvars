region   = "ap-south-1"
vpc_name = "eks-vpc-ap-south-1"
vpc_cidr = "10.0.0.0/16"

# Provide multiple AZs
azs = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

# Provide a single public subnet base; it will be split into 3 subnets
# Starting with /24, splitting into 3 subnets will actually use newbits=2 (up to 4 subnets),
# creating four /26 subnets; first 3 will be used.
public_subnets      = ["10.0.1.0/24"]
public_subnet_names = ["public-subnet"]

private_subnets      = ["10.0.101.0/24"]
private_subnet_names = ["private-subnet"]

instance_type = "t3.micro"

cidr_blocks_ingress_bastion = ["49.204.133.10/32"]
cidr_blocks_egress          = ["0.0.0.0/0"]