#get the current region from the provider block
data "aws_region" "current" {}

#get the list of Az's which is available in a region
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "kube"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Environment = "Dev"
  }


  depends_on = [aws_route53_zone.ekszone]
}

resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn = aws_acm_certificate.cert.arn
}

resource "aws_route53_zone" "ekszone" {
  name = var.domain_name
}

