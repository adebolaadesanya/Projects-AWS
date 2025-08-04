output "alb_certificate_arn" {
  description = "ARN of the ACM certificate for the ALB"
  value       = aws_acm_certificate.alb_certificate.arn
}

# Outputs
output "load_balancer_controller_policy_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM Policy"
  value       = aws_iam_policy.load_balancer_controller.arn
}

output "load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM Role"
  value       = aws_iam_role.load_balancer_controller.arn
}

output "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL for ALB"
  value       = aws_wafv2_web_acl.regional.arn
}

output "website_url" {
  description = "The full domain name of the website"
  value       = "https://${var.record_name}.${var.domain_name}"
}