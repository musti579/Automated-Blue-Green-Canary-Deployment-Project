# Requests a public ACM certificate for api.urlshortening.net, validated via DNS
resource "aws_acm_certificate" "api_cert" {
  domain_name       = "api.urlshortening.net"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

