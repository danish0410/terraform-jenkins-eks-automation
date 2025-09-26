region   = "us-east-1"
vpc_name = "eks-vpc-us-east-1"
vpc_cidr = "10.1.0.0/16"

azs = ["us-east-1a", "us-east-1b"]

public_subnets      = ["10.1.1.0/24", "10.1.2.0/24"]
public_subnet_names = ["public-subnet-1", "public-subnet-2"]

private_subnets      = ["10.1.101.0/24", "10.1.102.0/24"]
private_subnet_names = ["private-subnet-1", "private-subnet-2"]

ami           = "ami-053b0d53c279acc90"
instance_type = "t3.micro"

key_name         = "terraform-key-us-east-1"
public_key_path  = "/home/thani/.ssh/id_rsa.pub"
private_key_path = "/home/thani/.ssh/id_rsa"

cidr_blocks_ingress_bastion = ["49.204.129.43/32"]
cidr_blocks_egress          = ["0.0.0.0/0"]