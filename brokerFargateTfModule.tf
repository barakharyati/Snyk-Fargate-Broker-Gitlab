locals {
  broker_Client_URL = "https://${var.nameprefix}-${var.task_name}.${var.r53_zone}:${tostring(var.broker_port)}"
  logGroupPath      = "/ecs/${var.nameprefix}-${var.task_name}"

  certificate_arn      = var.certificate_arn != "" ? var.certificate_arn : data.aws_acm_certificate.domain_cert.arn
  fargateHostIp        = "127.0.0.1"
  healthCheckSleepTime = "120"
}
resource "aws_lb" "broker_aws_alb" {
  name               = lower("${var.nameprefix}-${var.task_name}")
  internal           = true
  load_balancer_type = "application"
  subnets            = var.FARGATE_Subnets
  security_groups    = [aws_security_group.ALB_SecurityGroup.id]
}

resource "aws_lb_target_group" "lb_target_group" {
  name        = lower("${var.nameprefix}-${var.task_name}-tg")
  port        = var.broker_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_subnet.ecs_service_Subnet.vpc_id
  health_check {
    enabled             = true
    path                = "/"
    port                = var.broker_port
    interval            = 30
    unhealthy_threshold = 5
    healthy_threshold   = 3
    timeout             = 10
    matcher             = "200,401"
  }
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.broker_aws_alb.arn
  port              = var.broker_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = local.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
}

resource "aws_route53_record" "snyk_broker_dns_record" {
  zone_id = data.aws_route53_zone.r53_zone.id
  name    = "${var.nameprefix}-${var.task_name}"
  type    = "A"
  #ttl = 60
  alias {
    name                   = aws_lb.broker_aws_alb.dns_name
    zone_id                = aws_lb.broker_aws_alb.zone_id
    evaluate_target_health = true
  }
}



resource "aws_cloudwatch_log_group" "snyk_broker_Log_Group" {
  name = local.logGroupPath
}



resource "aws_iam_role" "ecs-task-exe-iam-role" {
  name        = "${var.nameprefix}-${lower(var.task_name)}-container-execution-role"
  description = "${var.nameprefix}-${lower(var.task_name)} container  execution role"

  assume_role_policy = jsonencode(
    {
      "Version" : "2008-10-17",
      "Statement" : [
        {
          "Sid" : "",
          "Effect" : "Allow",
          "Principal" : {
            "Service" : "ecs-tasks.amazonaws.com"
          },
          "Action" : "sts:AssumeRole"
        }
      ]
    }
  )
  inline_policy {
    name = "${var.nameprefix}-${lower(var.task_name)}-container-execution-policy"
    policy = jsonencode(
      {
        "Version" : "2012-10-17",
        "Statement" : [
          {
            "Sid" : "secretManagerPermissions",
            "Effect" : "Allow",
            "Action" : [
              "secretsmanager:GetSecretValue",
              "kms:Decrypt"
            ],
            "Resource" : [
              var.exe_task_ssm_secret,
              var.registry_token_fargate_ssm_secret
            ]
          },
          {
            "Sid" : "CloudWatchPermissions",
            "Effect" : "Allow",
            "Action" : [
              "logs:CreateLogStream",
              "logs:PutLogEvents"
            ],
            "Resource" : [
              "arn:aws:logs:*:*:log-group:${local.logGroupPath}*:log-stream:*",
              "arn:aws:logs:*:*:log-group:${local.logGroupPath}*"
            ]
          }
        ]
      }

    )
  }
}


resource "aws_security_group" "ALB_SecurityGroup" {
  name        = "ALB_${var.nameprefix}_${var.task_name}_securityGroup"
  description = "ALB_${var.nameprefix}_${var.task_name} ecs task securityGroup"
  vpc_id      = data.aws_subnet.ecs_service_Subnet.vpc_id
  tags = {
    "Name" = "ALB_${var.nameprefix}_${var.task_name}_securityGroup"
  }

  dynamic "ingress" {
    for_each = var.ALB_SG_Ingress_Rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = ingress.value.protocol
      security_groups  = ingress.value.security_groups
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
    }
  }
}

resource "aws_security_group" "FARGATE_SecurityGroup" {
  name        = "FARGATE_${var.nameprefix}_${var.task_name}_securityGroup"
  description = "FARGATE_${var.nameprefix}_${var.task_name} ecs task securityGroup"
  vpc_id      = data.aws_subnet.ecs_service_Subnet.vpc_id
  tags = {
    Name = "FARGATE_${var.nameprefix}_${var.task_name}_securityGroup"
  }

  dynamic "ingress" {
    for_each = var.fargate_SG_Ingress_Rules
    content {
      description      = ingress.value.description
      from_port        = ingress.value.port
      to_port          = ingress.value.port
      protocol         = ingress.value.protocol
      security_groups  = ingress.value.security_groups
      cidr_blocks      = ingress.value.cidr_blocks
      ipv6_cidr_blocks = ingress.value.ipv6_cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.Fargate_SG_egress_rules
    content {
      description      = egress.value.description
      from_port        = egress.value.port
      to_port          = egress.value.port
      protocol         = egress.value.protocol
      security_groups  = egress.value.security_groups
      cidr_blocks      = egress.value.cidr_blocks
      ipv6_cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_security_group_rule" "ALB_2_Fargate_SG_rule_Ingress" {
  type                     = "ingress"
  description              = "ALB to Fargate access on port ${var.broker_port} inbound Rule "
  from_port                = var.broker_port
  to_port                  = var.broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.FARGATE_SecurityGroup.id
  source_security_group_id = aws_security_group.ALB_SecurityGroup.id
}

resource "aws_security_group_rule" "ALB_2_Fargate_SG_rule_egress" {
  type                     = "egress"
  description              = "ALB to Fargate access on port ${var.broker_port} outbound Rule "
  from_port                = var.broker_port
  to_port                  = var.broker_port
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ALB_SecurityGroup.id
  source_security_group_id = aws_security_group.FARGATE_SecurityGroup.id
}
