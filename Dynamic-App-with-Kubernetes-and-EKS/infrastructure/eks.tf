# Create EKS cluster
resource "aws_eks_cluster" "cluster" {
  name     = "${var.project_name}-${var.environment}-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      aws_subnet.private_app_subnet_az1.id,
      aws_subnet.private_app_subnet_az2.id
    ]

    # Cluster endpoint access configuration
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  depends_on = [
    aws_iam_role.eks_cluster_role,
    aws_cloudwatch_log_group.eks_cluster_logs
  ]
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = "${var.project_name}-${var.environment}-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private_app_subnet_az1.id,
    aws_subnet.private_app_subnet_az2.id
  ]

  # Instance type configuration
  instance_types = var.eks_node_instance_types

  # Capacity type (ON_DEMAND or SPOT)
  capacity_type = var.eks_node_capacity_type

  # Disk configuration
  disk_size = var.eks_node_disk_size

  # AMI type (AL2_x86_64, AL2_x86_64_GPU, AL2_ARM_64, etc.)
  ami_type = var.eks_node_ami_type

  # Node tags - enable SSM access by adding the AmazonSSMManagedInstanceCore tag
  tags = {
    "Name" = "${var.project_name}-${var.environment}-eks-node"
    # This tag allows SSM to recognize the instances
    "aws:eks:cluster-name" = aws_eks_cluster.cluster.name
  }

  scaling_config {
    desired_size = 4
    max_size     = 10
    min_size     = 3
  }

  depends_on = [
    aws_iam_role.eks_node_role
  ]
}

# Enable Container Insights as an EKS addon
resource "aws_eks_addon" "container_insights" {
  cluster_name  = aws_eks_cluster.cluster.name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = "v3.5.0-eksbuild.1" # Use the latest version available
  # run: <aws eks describe-addon-versions --addon-name amazon-cloudwatch-observability> to check what's the latest version


  # This is important to avoid Terraform trying to replace the add-on
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  depends_on = [
    aws_eks_cluster.cluster,
    aws_eks_node_group.main
  ]
}

# Attach CloudWatch Agent Server Policy to the node role
# This is required for Container Insights to work properly
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_server_policy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_node_role.name
}