# environment variables
variable "region" {
  description = "region to create resources"
  type        = string
}

variable "project_name" {
  description = "project name"
  type        = string
}

variable "environment" {
  description = "environment"
  type        = string
}

# vpc variables
variable "vpc_cidr" {
  description = "vpc cidr block"
  type        = string
}

variable "public_subnet_az1_cidr" {
  description = "public subnet az1 cidr block"
  type        = string
}

variable "public_subnet_az2_cidr" {
  description = "public subnet az2 cidr block"
  type        = string
}

variable "private_app_subnet_az1_cidr" {
  description = "private app subnet az1 cidr block"
  type        = string
}

variable "private_app_subnet_az2_cidr" {
  description = "private app subnet az2 cidr block"
  type        = string
}

variable "data_subnet_az1_cidr" {
  description = "private app subnet az1 cidr block"
  type        = string
}

variable "data_subnet_az2_cidr" {
  description = "private app subnet az2 cidr block"
  type        = string
}

# Database Variables
variable "engine" {
  description = "Database engine"
  type        = string
}

variable "engine_version" {
  description = "Version of the engine"
  type        = string
}

variable "instance_class" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
}

variable "allocated_storage" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
}

variable "max_allocated_storage" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
}

variable "storage_type" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
}

variable "db_name" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
}

variable "parameter_group_name" {
  description = "Username for the RDS PostgreSQL instance"
  type        = string
}

# EKS Node Group variables
variable "eks_node_instance_types" {
  description = "Instance types for EKS node group"
  type        = list(string)
}

variable "eks_node_capacity_type" {
  description = "Capacity type for EKS node group (ON_DEMAND or SPOT)"
  type        = string
}

variable "eks_node_disk_size" {
  description = "Disk size in GB for EKS node group instances"
  type        = number
}

variable "eks_node_ami_type" {
  description = "AMI type for EKS node group (AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, etc.)"
  type        = string
}

# route53 variables
variable "domain_name" {
  description = "domain name"
  type        = string
}

variable "alternative_names" {
  description = "sub domain name"
  type        = string
}

variable "record_name" {
  description = "sub domain name"
  type        = string
}

# SNS variables
variable "email" {
  description = "Email for receiving sns alerts"
  type        = string
}