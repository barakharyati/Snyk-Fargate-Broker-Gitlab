output "task_definition_Arn" {
  value = aws_ecs_task_definition.task_definition.arn

}

output "ecs_Service_Arn" {
  value = aws_ecs_service.Snyk_Broker_Ecs_Service.id
}

output "broker_Client_URL" {
  value = local.broker_Client_URL
}

output "ecs_snyk_broker_log-Group" {
  value = aws_cloudwatch_log_group.snyk_broker_Log_Group
}
output "ecs-task-exe-iam-role" {
  value = aws_iam_role.ecs-task-exe-iam-role.arn
}

output "broker_aws_alb" {
  value = aws_lb.broker_aws_alb
}

output "snyk_broker_dns_record" {
  value = aws_route53_record.snyk_broker_dns_record.fqdn
}

output "default_domain_cert" {
  value = { "certDomain": data.aws_acm_certificate.domain_cert.domain, "certARN": data.aws_acm_certificate.domain_cert.arn,  "certStatus": data.aws_acm_certificate.domain_cert.status}
}