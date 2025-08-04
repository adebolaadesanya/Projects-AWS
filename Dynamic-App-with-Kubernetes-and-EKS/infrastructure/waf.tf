# Regional WAF (for ALB)
resource "aws_wafv2_web_acl" "regional" {
  name        = "${var.project_name}-${var.environment}-regional-acl"
  description = "WAF for protecting Application Load Balancer"
  scope       = "REGIONAL"
  provider    = aws

  default_action {
    allow {}
  }

  # SQL Injection Protection
  rule {
    name     = "SQLInjectionRule"
    priority = 1

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRule"
      sampled_requests_enabled   = true
    }
  }

  # XSS Protection
  rule {
    name     = "XSSRule"
    priority = 2

    action {
      block {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRule"
      sampled_requests_enabled   = true
    }
  }

  # Rate-Based Rule (DDoS Protection)
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 3000
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # AWS Core Rule Set (commonly used protections)
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Bot Control
  rule {
    name     = "AWS-AWSManagedRulesBotControlRuleSet"
    priority = 5

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesBotControlRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesBotControlRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "regionalWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-regional-acl"
    Environment = var.environment
  }
}

# CloudFront WAF (Global)
resource "aws_wafv2_web_acl" "cloudfront" {
  provider    = aws.us_east_1
  name        = "${var.project_name}-${var.environment}-cloudfront-acl"
  description = "WAF for protecting CloudFront distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # SQL Injection Protection
  rule {
    name     = "SQLInjectionRule"
    priority = 1

    action {
      block {}
    }

    statement {
      sqli_match_statement {
        field_to_match {
          query_string {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "SQLInjectionRule"
      sampled_requests_enabled   = true
    }
  }

  # XSS Protection
  rule {
    name     = "XSSRule"
    priority = 2

    action {
      block {}
    }

    statement {
      xss_match_statement {
        field_to_match {
          body {}
        }
        text_transformation {
          priority = 1
          type     = "URL_DECODE"
        }
        text_transformation {
          priority = 2
          type     = "HTML_ENTITY_DECODE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "XSSRule"
      sampled_requests_enabled   = true
    }
  }

  # Rate-Based Rule (DDoS Protection)
  rule {
    name     = "RateLimitRule"
    priority = 3

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 5000 # Higher limit for CloudFront
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # AWS Core Rule Set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 4

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWS-AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "cloudfrontWebACL"
    sampled_requests_enabled   = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront-acl"
    Environment = var.environment
  }
}

# CloudWatch Log Group for Regional WAF logs (eu-west-1)
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "aws-waf-logs-${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-logs"
    Environment = var.environment
  }
}

# CloudWatch Log Group for CloudFront WAF logs (us-east-1)
resource "aws_cloudwatch_log_group" "waf_logs_us_east" {
  provider          = aws.us_east_1
  name              = "aws-waf-logs-${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = {
    Name        = "${var.project_name}-${var.environment}-waf-logs-global"
    Environment = var.environment
  }
}

# Enable WAF logging for Regional WAF
resource "aws_wafv2_web_acl_logging_configuration" "regional_logs" {
  resource_arn            = aws_wafv2_web_acl.regional.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs.arn]
}

# Enable WAF logging for CloudFront WAF
resource "aws_wafv2_web_acl_logging_configuration" "cloudfront_logs" {
  provider                = aws.us_east_1
  resource_arn            = aws_wafv2_web_acl.cloudfront.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf_logs_us_east.arn]
}

# Metric filter for all blocked requests
resource "aws_cloudwatch_log_metric_filter" "blocked_requests" {
  name           = "${var.project_name}-${var.environment}-blocked-requests"
  pattern        = "{ $.action = \"BLOCK\" }"
  log_group_name = aws_cloudwatch_log_group.waf_logs.name

  metric_transformation {
    name      = "BlockedRequests"
    namespace = "WAF"
    value     = "1"
  }
}

# Alarm for high number of blocked requests (overall)
resource "aws_cloudwatch_metric_alarm" "high_blocked_requests" {
  alarm_name          = "${var.project_name}-${var.environment}-high-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "BlockedRequests"
  namespace           = "WAF"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This alarm monitors for high numbers of blocked WAF requests"
  
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Metric filter for SQL injection attacks
resource "aws_cloudwatch_log_metric_filter" "sql_injection_attacks" {
  name           = "${var.project_name}-${var.environment}-sql-injection"
  pattern        = "{ $.ruleGroupList.0.terminatingRule.ruleId = \"SQLInjectionRule\" }"
  log_group_name = aws_cloudwatch_log_group.waf_logs.name

  metric_transformation {
    name      = "SQLInjectionAttacks"
    namespace = "WAF"
    value     = "1"
  }
}

# Alarm for SQL injection attacks
resource "aws_cloudwatch_metric_alarm" "sql_injection_attacks" {
  alarm_name          = "${var.project_name}-${var.environment}-sql-injection-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "SQLInjectionAttacks"
  namespace           = "WAF"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This alarm triggers when multiple SQL injection attacks are detected"
  
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# Metric filter for XSS attacks
resource "aws_cloudwatch_log_metric_filter" "xss_attacks" {
  name           = "${var.project_name}-${var.environment}-xss-attacks"
  pattern        = "{ $.ruleGroupList.0.terminatingRule.ruleId = \"XSSRule\" }"
  log_group_name = aws_cloudwatch_log_group.waf_logs.name

  metric_transformation {
    name      = "XSSAttacks"
    namespace = "WAF"
    value     = "1"
  }
}

# Alarm for XSS attacks
resource "aws_cloudwatch_metric_alarm" "xss_attacks" {
  alarm_name          = "${var.project_name}-${var.environment}-xss-attacks-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "XSSAttacks"
  namespace           = "WAF"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "This alarm triggers when multiple XSS attacks are detected"
  
  alarm_actions       = [aws_sns_topic.alerts.arn]
}

# CloudWatch Dashboard for WAF
resource "aws_cloudwatch_dashboard" "waf_dashboard" {
  dashboard_name = "${var.project_name}-${var.environment}-waf-dashboard"

  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "WAF", "BlockedRequests", { "stat": "Sum", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${data.aws_region.current.name}",
        "title": "Total Blocked Requests"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "WAF", "SQLInjectionAttacks", { "stat": "Sum", "period": 300 } ],
          [ "WAF", "XSSAttacks", { "stat": "Sum", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${data.aws_region.current.name}",
        "title": "Attack Breakdown"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 24,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/WAFV2", "BlockedRequests", "WebACL", "${aws_wafv2_web_acl.regional.name}", "Region", "${data.aws_region.current.name}", { "stat": "Sum", "period": 300 } ],
          [ "AWS/WAFV2", "AllowedRequests", "WebACL", "${aws_wafv2_web_acl.regional.name}", "Region", "${data.aws_region.current.name}", { "stat": "Sum", "period": 300 } ]
        ],
        "view": "timeSeries",
        "stacked": false,
        "region": "${data.aws_region.current.name}",
        "title": "Regional WAF - Allowed vs Blocked"
      }
    }
  ]
}
EOF

  depends_on = [
    aws_wafv2_web_acl.regional,
    aws_wafv2_web_acl.cloudfront
  ]
}

# Get current region for use in dashboard
data "aws_region" "current" {}