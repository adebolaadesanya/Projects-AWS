# We don't need to create security groups for the EKS cluster and for the Load Balancer
# because AWS EKS will automatically create them for us when we create our EKS cluster.

# Database Security Group
resource "aws_security_group" "surveys_db_sg" {
  name        = "${var.project_name}-${var.environment}-surveys-db-sg"
  description = "Security group for Surveys RDS database"
  vpc_id      = aws_vpc.vpc.id

  # Empty to start - we'll add rules after
  tags = {
    Name = "${var.project_name}-${var.environment}-surveys-db-sg"
  }
}

# Add ingress rule after EKS cluster is created
resource "aws_security_group_rule" "rds_from_eks" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.surveys_db_sg.id
  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description              = "Allow PostgreSQL access from EKS cluster"

  depends_on = [aws_eks_cluster.cluster]
}

# Add egress rule
resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.surveys_db_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound traffic"
}

# Consolidated security group for all VPC endpoints
resource "aws_security_group" "vpc_endpoints_sg" {
  name        = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  description = "Allow TLS inbound traffic for the different VPC endpoints"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "TLS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-vpc-endpoints-sg"
  }
}

# Add explicit rule for EKS cluster
resource "aws_security_group_rule" "vpc_endpoints_from_eks" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.vpc_endpoints_sg.id
  source_security_group_id = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
  description              = "Allow HTTPS access from EKS cluster"
}