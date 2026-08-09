# Requests a public ACM certificate for api.urlshortening.net, validated via DNS
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api.urlshortening.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


# Creates the DNS record ACM needs to verify we own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.api_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Waits until ACM confirms the certificate is fully validated
resource "aws_acm_certificate_validation" "api_cert" {
  certificate_arn         = aws_acm_certificate.api_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Looks up the existing Route 53 hosted zone for urlshortening.net
data "aws_route53_zone" "main" {
  name = "urlshortening.net"
}

# Points api.urlshortening.net at the ALB using an ALIAS record
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "api.urlshortening.net"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# --- Frontend domain (points urlshortening.net at CloudFront) ---

# CloudFront certs must be requested in us-east-1 regardless of where everything else lives
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Certificate for the frontend's bare domain, must be in us-east-1 for CloudFront to use it
resource "aws_acm_certificate" "frontend_cert" {
  provider          = aws.us_east_1
  domain_name       = "urlshortening.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# DNS record ACM needs to validate ownership of the frontend's domain
resource "aws_route53_record" "frontend_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.frontend_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

# Waits for the frontend certificate to be fully validated
resource "aws_acm_certificate_validation" "frontend_cert" {
  provider                = aws.us_east_1
  certificate_arn          = aws_acm_certificate.frontend_cert.arn
  validation_record_fqdns  = [for record in aws_route53_record.frontend_cert_validation : record.fqdn]
}

# Exposes the validated frontend cert's ARN so the frontend module's CloudFront distribution can use it
output "frontend_certificate_arn" {
  value = aws_acm_certificate_validation.frontend_cert.certificate_arn
}