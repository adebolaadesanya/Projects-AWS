# environment variables
region       = "<your region>"
project_name = "topsurvey"
environment  = "dev"

# vpc variables
vpc_cidr                    = "10.0.0.0/16"
public_subnet_az1_cidr      = "10.0.0.0/24"
public_subnet_az2_cidr      = "10.0.1.0/24"
private_app_subnet_az1_cidr = "10.0.2.0/24"
private_app_subnet_az2_cidr = "10.0.3.0/24"
data_subnet_az1_cidr        = "10.0.4.0/24"
data_subnet_az2_cidr        = "10.0.5.0/24"

# Database Variables
engine                = "postgres"
engine_version        = "17.4"
instance_class        = "db.r5.2xlarge"
allocated_storage     = 200
max_allocated_storage = 1000
storage_type          = "gp3"
db_name               = "surveys"
parameter_group_name  = "default.postgres17"

# EKS Node Group variables
eks_node_instance_types = ["m5.2xlarge"]
eks_node_capacity_type  = "ON_DEMAND"
eks_node_disk_size      = 100
eks_node_ami_type       = "AL2_x86_64"

# route53 variables
domain_name       = "<your domain name>"
alternative_names = "*.<your domain name>"
record_name       = "topsurvey"

# SNS variables
email = "<your email>"