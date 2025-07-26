# Production Environment
region   = "ap-south-1"
vpc_cidr = "10.0.0.0/16"
vpc_name = "eks-vpc"

web_sub_cidr            = "10.0.21.0/24"
web_availability_zone1a = "ap-south-1a"
web_sub_name            = "public-subnet-1a-prod"

app_sub_cidr_1a         = "10.0.23.0/24"
app_availability_zone1a = "ap-south-1a"
app_sub_name_1a         = "private-subnet-1a-prod"

app_sub_cidr_1b         = "10.0.24.0/24"
app_availability_zone1b = "ap-south-1b"
app_sub_name_1b         = "private-subnet-1b-prod"

db_sub_cidr            = "10.0.25.0/24"
db_availability_zone1a = "ap-south-1a"
db_sub_name            = "db-subnet-1a-prod"

eks_cluster_name   = "poc-eks-cluster-prod"
eks_nodegroup_name = "poc-eks-nodes-prod"

desired_capacity = 3
min_size         = 2
max_size         = 5
instance_type    = "t3.large"

aws_ami               = "ami-0f5ee92e2d63afc18"
bastion_instance_type = "t3.micro"
public_key_path       = "~/.ssh/id_rsa.pub"

env               = "prod"
my_igw_name       = "prod-igw"
pub_route_name    = "prod-public-rt"
pri_route_name    = "prod-private-rt"
vpc_route_cidr    = "0.0.0.0/0"
log_bucket_prefix = "tf-backup-aws-prod"