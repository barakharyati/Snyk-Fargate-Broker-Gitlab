data "aws_subnet" "ecs_service_Subnet" {
  id = sort(var.FARGATE_Subnets)[0]
}

data "aws_route53_zone" "r53_zone" {
  name         = var.r53_zone
  private_zone = false
}

data "aws_acm_certificate" "domain_cert" {
  domain      = var.r53_zone
  types       = ["AMAZON_ISSUED"]
  most_recent = true
  #statuses = ["PENDING_VALIDATION", "ISSUED"]
  statuses = ["ISSUED"]
}
