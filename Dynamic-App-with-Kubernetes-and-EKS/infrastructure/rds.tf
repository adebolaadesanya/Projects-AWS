# RDS Subnet Group
resource "aws_db_subnet_group" "surveys_db_subnet_group" {
  name       = "${var.project_name}-${var.environment}-db-subnet-grp"
  subnet_ids = [aws_subnet.private_data_subnet_az1.id, aws_subnet.private_data_subnet_az2.id]
  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-grp"
  }
}

# Generate a random username
resource "random_string" "db_username" {
  length  = 8
  special = false
  numeric = true
  upper   = false
}

# Generate a random password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# RDS PostgreSQL instance
resource "aws_db_instance" "surveys_db" {
  identifier                = "${var.project_name}-${var.environment}-surveys-db"
  engine                    = var.engine
  engine_version            = var.engine_version
  instance_class            = var.instance_class
  allocated_storage         = var.allocated_storage
  max_allocated_storage     = var.max_allocated_storage
  storage_type              = var.storage_type
  db_name                   = var.db_name
  username                  = random_string.db_username.result
  password                  = random_password.db_password.result
  parameter_group_name      = var.parameter_group_name
  db_subnet_group_name      = aws_db_subnet_group.surveys_db_subnet_group.name
  skip_final_snapshot       = true # Changed to false in development
  final_snapshot_identifier = "${var.project_name}-${var.environment}-final-snapshot"
  vpc_security_group_ids    = [aws_security_group.surveys_db_sg.id]
  multi_az                  = true
  backup_retention_period   = 30
  backup_window             = "02:00-03:00"
  maintenance_window        = "mon:04:00-mon:05:00"
  storage_encrypted         = true
  delete_automated_backups  = false

  # Reference to monitoring configuration defined in cloudwatch.tf
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_monitoring_role.arn

  # Performance insights
  performance_insights_enabled          = true
  performance_insights_retention_period = 731

  # Enable automated backups to S3
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  tags = {
    Name        = "${var.project_name}-${var.environment}-surveys-db"
    Environment = var.environment
    Backup      = "daily"
  }
}

# Store credentials in Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name = "${var.project_name}-${var.environment}-db-credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    host     = aws_db_instance.surveys_db.address
    user     = random_string.db_username.result
    password = random_password.db_password.result
    database = aws_db_instance.surveys_db.db_name
  })
}