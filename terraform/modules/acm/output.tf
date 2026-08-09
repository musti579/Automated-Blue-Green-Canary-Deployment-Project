# Exposes the validated certificate's ARN so other modules (like ALB) can reference it
output "certificate_arn" {
  value = aws_acm_certificate_validation.api_cert.certificate_arn
}
