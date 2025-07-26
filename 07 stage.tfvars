# Staging Environment
region   = "ap-south-1"
vpc_cidr = "10.0.0.0/16"
vpc_name = "eks-vpc"

web_sub_cidr            = "10.0.11.0/24"
web_availability_zone1a = "ap-south-1a"
web_sub_name            = "public-subnet-1a-stage"

app_sub_cidr_1a         = "10.0.13.0/24"
app_availability_zone1a = "ap-south-1a"
app_sub_name_1a         = "private-subnet-1a-stage"

app_sub_cidr_1b         = "10.0.14.0/24"
app_availability_zone1b = "ap-south-1b"
app_sub_name_1b         = "private-subnet-1b-stage"

db_sub_cidr            = "10.0.15.0/24"
db_availability_zone1a = "ap-south-1a"
db_sub_name            = "db-subnet-1a-stage"

eks_cluster_name   = "poc-eks-cluster-stage"
eks_nodegroup_name = "poc-eks-nodes-stage"

desired_capacity = 2
min_size         = 1
max_size         = 3
instance_type    = "t3.medium"

aws_ami               = "ami-0f5ee92e2d63afc18"
bastion_instance_type = "t3.micro"
public_key_path       = "~/.ssh/id_rsa.pub"

env               = "stage"
my_igw_name       = "stage-igw"
pub_route_name    = "stage-public-rt"
pri_route_name    = "stage-private-rt"
vpc_route_cidr    = "0.0.0.0/0"
log_bucket_prefix = "tf-backup-aws-stage"