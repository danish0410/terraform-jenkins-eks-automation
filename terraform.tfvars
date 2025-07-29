region                  = "ap-south-1"
vpc_cidr                = "10.0.0.0/16"
vpc_name                = "eks-vpc"
web_sub_cidr            = "10.0.1.0/24"
web_availability_zone1a = "ap-south-1a"
web_sub_name            = "web-subnet-1a"

app_sub_cidr_1a         = "10.0.2.0/24"
app_availability_zone1a = "ap-south-1a"
app_sub_name_1a         = "app-subnet-1a"

app_sub_cidr_1b         = "10.0.3.0/24"
app_availability_zone1b = "ap-south-1b"
app_sub_name_1b         = "app-subnet-1b"

db_sub_cidr            = "10.0.4.0/24"
db_availability_zone1a = "ap-south-1a"
db_sub_name            = "db-subnet-1a"

eks_cluster_name      = "eks-cluster"
eks_nodegroup_name    = "eks-nodes"
desired_capacity      = 2
min_size              = 1
max_size              = 3
instance_type         = "t3.medium"
aws_ami               = "ami-03f4878755434977f"
bastion_instance_type = "t2.micro"
public_key_path       = "/home/thani/.ssh/id_rsa.pub"
env                   = "dev"

my_igw_name       = "dev-igw"
pub_route_name    = "dev-public-rt"
pri_route_name    = "dev-private-rt"
vpc_route_cidr    = "0.0.0.0/0"
log_bucket_prefix = "logs"
s3_bucket_name    = "dev-tf-state-bucket"
