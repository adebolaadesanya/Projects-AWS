# Create Cloudwatch log group for EKS cluster
resource "aws_cloudwatch_log_group" "eks_cluster_logs" {
  name              = "${var.project_name}-${var.environment}-cloudwatch-logs"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudwatch-logs"
    Environment = var.environment
  }
}

# EKS Control Plane Metrics Alarms - Using native CloudWatch metrics
resource "aws_cloudwatch_metric_alarm" "eks_cluster_api_errors" {
  alarm_name          = "${var.project_name}-${var.environment}-eks-api-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "This alarm monitors EKS API server errors"

  dimensions = {
    ClusterName = aws_eks_cluster.cluster.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "eks_control_plane_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-eks-control-plane-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "cluster_failed_node_count"
  namespace           = "AWS/EKS"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "This metric monitors EKS control plane CPU usage"

  dimensions = {
    ClusterName = aws_eks_cluster.cluster.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# Container Insights Alarms - These alarms use the ContainerInsights namespace
resource "aws_cloudwatch_metric_alarm" "pod_cpu_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-pod-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "pod_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors pod CPU utilization"

  dimensions = {
    ClusterName = aws_eks_cluster.cluster.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  depends_on = [
    aws_eks_addon.container_insights
  ]
}

resource "aws_cloudwatch_metric_alarm" "pod_memory_utilization" {
  alarm_name          = "${var.project_name}-${var.environment}-pod-high-memory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "pod_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors pod memory utilization"

  dimensions = {
    ClusterName = aws_eks_cluster.cluster.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  depends_on = [
    aws_eks_addon.container_insights
  ]
}

# Enhanced CloudWatch Dashboard for EKS with Container Insights metrics
resource "aws_cloudwatch_dashboard" "eks_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-eks-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      # Control Plane Metrics
      {
        type   = "text",
        x      = 0,
        y      = 0,
        width  = 24,
        height = 1,
        properties = {
          markdown = "## EKS Control Plane Metrics"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 1,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_request_count", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Sum",
          region = var.region,
          title  = "EKS API Request Count"
        }
      },
      {
        type   = "metric",
        x      = 8,
        y      = 1,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Maximum",
          region = var.region,
          title  = "Failed Nodes"
        }
      },
      {
        type   = "metric",
        x      = 16,
        y      = 1,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EKS", "http_requests_total", "ClusterName", aws_eks_cluster.cluster.name],
            ["AWS/EKS", "http_2xx_requests_total", "ClusterName", aws_eks_cluster.cluster.name],
            ["AWS/EKS", "http_4xx_requests_total", "ClusterName", aws_eks_cluster.cluster.name],
            ["AWS/EKS", "http_5xx_requests_total", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Sum",
          region = var.region,
          title  = "API Request Response Distribution"
        }
      },

      # Container Insights Metrics
      {
        type   = "text",
        x      = 0,
        y      = 7,
        width  = 24,
        height = 1,
        properties = {
          markdown = "## Container Insights Metrics"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 8,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", aws_eks_cluster.cluster.name, "Namespace", "All"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Pod CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 8,
        y      = 8,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", aws_eks_cluster.cluster.name, "Namespace", "All"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Pod Memory Utilization"
        }
      },
      {
        type   = "metric",
        x      = 16,
        y      = 8,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "pod_number", "ClusterName", aws_eks_cluster.cluster.name, "Namespace", "All"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Number of Pods"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 14,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Node CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 8,
        y      = 14,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "node_memory_utilization", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Node Memory Utilization"
        }
      },
      {
        type   = "metric",
        x      = 16,
        y      = 14,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "node_number", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Number of Nodes"
        }
      },

      # Logs Section
      {
        type   = "log",
        x      = 0,
        y      = 20,
        width  = 24,
        height = 6,
        properties = {
          query  = "SOURCE '/aws/containerinsights/${aws_eks_cluster.cluster.name}/application' | fields @timestamp, @message | sort @timestamp desc | limit 100",
          region = var.region,
          title  = "Recent Container Application Logs"
        }
      }
    ]
  })

  depends_on = [
    aws_eks_addon.container_insights
  ]
}

# EC2 Auto Scaling Group Metrics for EKS Nodes
resource "aws_cloudwatch_metric_alarm" "eks_node_group_high_cpu" {
  alarm_name          = "${var.project_name}-${var.environment}-eks-nodes-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors EC2 instances in the EKS node group for high CPU"

  dimensions = {
    AutoScalingGroupName = "${var.project_name}-${var.environment}-node-group-*"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

# CloudWatch alarm for RDS high CPU utilization
resource "aws_cloudwatch_metric_alarm" "rds_cpu_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "This alarm monitors RDS database CPU utilization"

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-${var.environment}-surveys-db"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-high-cpu"
  }
}

# CloudWatch alarm for RDS low free storage space
resource "aws_cloudwatch_metric_alarm" "rds_storage_alarm" {
  alarm_name          = "${var.project_name}-${var.environment}-rds-low-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 5000000000 # 5GB in bytes
  alarm_description   = "This alarm monitors RDS database free storage space"

  dimensions = {
    DBInstanceIdentifier = "${var.project_name}-${var.environment}-surveys-db"
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Name = "${var.project_name}-${var.environment}-rds-low-storage"
  }
}

# RDS Dashboard
resource "aws_cloudwatch_dashboard" "rds_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-rds-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric",
        x      = 0,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 0,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Free Storage Space"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Database Connections"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 6,
        width  = 12,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "ReadIOPS", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"],
            ["AWS/RDS", "WriteIOPS", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Read/Write IOPS"
        }
      }
    ]
  })
}

# Comprehensive Dashboard with Container Insights
resource "aws_cloudwatch_dashboard" "all_services_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-all-services"

  dashboard_body = jsonencode({
    widgets = [
      # EKS Section
      {
        type   = "text",
        x      = 0,
        y      = 0,
        width  = 24,
        height = 1,
        properties = {
          markdown = "# EKS Cluster Metrics"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 1,
        width  = 6,
        height = 6,
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed_node_count", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Maximum",
          region = var.region,
          title  = "Failed Nodes"
        }
      },
      {
        type   = "metric",
        x      = 6,
        y      = 1,
        width  = 6,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", "ClusterName", aws_eks_cluster.cluster.name]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Node CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 12,
        y      = 1,
        width  = 6,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", aws_eks_cluster.cluster.name, "Namespace", "All"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Pod CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 18,
        y      = 1,
        width  = 6,
        height = 6,
        properties = {
          metrics = [
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", aws_eks_cluster.cluster.name, "Namespace", "All"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Pod Memory Utilization"
        }
      },

      # RDS Section
      {
        type   = "text",
        x      = 0,
        y      = 7,
        width  = 24,
        height = 1,
        properties = {
          markdown = "# RDS Database Metrics"
        }
      },
      {
        type   = "metric",
        x      = 0,
        y      = 8,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Database CPU Utilization"
        }
      },
      {
        type   = "metric",
        x      = 8,
        y      = 8,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "FreeStorageSpace", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Database Free Storage"
        }
      },
      {
        type   = "metric",
        x      = 16,
        y      = 8,
        width  = 8,
        height = 6,
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", "DBInstanceIdentifier", "${var.project_name}-${var.environment}-surveys-db"]
          ],
          period = 300,
          stat   = "Average",
          region = var.region,
          title  = "Database Connections"
        }
      }
    ]
  })

  depends_on = [
    aws_eks_addon.container_insights
  ]
}