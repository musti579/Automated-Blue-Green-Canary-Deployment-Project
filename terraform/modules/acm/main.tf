# Requests a public ACM certificate for api.urlshortening.net, validated via DNS
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api.urlshortening.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Looks up the existing Route 53 hosted zone for urlshortening.net
data "aws_route53_zone" "main" {
  name = "urlshortening.net"
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

