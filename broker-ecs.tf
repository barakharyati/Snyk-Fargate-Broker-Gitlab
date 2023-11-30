resource "aws_ecs_task_definition" "task_definition" {
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.snyk_docker_cpu
  memory                   = var.snyk_docker_memory
  network_mode             = "awsvpc"

  family             = "${var.nameprefix}-${var.task_name}"
  execution_role_arn = aws_iam_role.ecs-task-exe-iam-role.arn
  container_definitions = jsonencode(
    [
      {
        "name" : "${var.nameprefix}-${var.task_name}"
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : local.logGroupPath,
            "awslogs-region" : var.aws_region,
            "awslogs-stream-prefix" : "ecs-${var.nameprefix}-${var.task_name}-"
          }
        },
        "portMappings" : [{
          "hostPort" : var.broker_port,
          "protocol" : "tcp",
          "containerPort" : var.broker_port
          }
        ],
        "environment" : [{
          "name" : "BROKER_CLIENT_URL",
          "value" : local.broker_Client_URL
          },
          {
            "name" : "GITLAB",
            "value" : var.gitlabServer
          },
          {
            "name" : "PORT",
            "value" : tostring(var.broker_port)
          },
          {
            "name" : "ACCEPT",
            "value" : "/home/node/accept.json"
          }
        ],
        "secrets" : [{
          "valueFrom" : "${var.exe_task_ssm_secret}:BROKER_TOKEN::",
          "name" : "BROKER_TOKEN"
          },
          {
            "valueFrom" : "${var.exe_task_ssm_secret}:GITLAB_TOKEN::",
            "name" : "GITLAB_TOKEN"
          }
        ],
        "image" : var.var_container_image,
        "repositoryCredentials" : {
          "credentialsParameter" : var.registry_token_fargate_ssm_secret
        }
        "essential" : true
      },
      {
        "name" : "test-broker-healthcheck",
        "dnsSearchDomains" : null,
        "environmentFiles" : null,
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "secretOptions" : null,
          "options" : {
            "awslogs-group" : local.logGroupPath,
            "awslogs-region" : var.aws_region,
            "awslogs-stream-prefix" : "ecs-${var.nameprefix}-${var.task_name}-healtCheck-"
          }
        },
        "entryPoint" : ["sh", "-c"],
        "portMappings" : [],
        "command" : [
          "/bin/sh -c 'echo install curl ; apk --no-cache add curl ; echo  sleep for 120 seconds ;sleep ${local.healthCheckSleepTime} ; echo run healtCheck ; curl http://${local.fargateHostIp}:8000/healthcheck ; echo run systemcheck ; curl http://${local.fargateHostIp}:8000/systemcheck'"
        ],
        "linuxParameters" : null,
        "cpu" : 0,
        "environment" : [],
        "resourceRequirements" : null,
        "ulimits" : null,
        "dnsServers" : null,
        "mountPoints" : [],
        "workingDirectory" : null,
        "secrets" : null,
        "dockerSecurityOptions" : null,
        "memory" : null,
        "memoryReservation" : null,
        "volumesFrom" : [],
        "stopTimeout" : null,
        "image" : "alpine",
        "startTimeout" : null,
        "firelensConfiguration" : null,
        "dependsOn" : null,
        "disableNetworking" : null,
        "interactive" : null,
        "healthCheck" : null,
        "essential" : false,
        "links" : null,
        "hostname" : null,
        "extraHosts" : null,
        "pseudoTerminal" : null,
        "user" : null,
        "readonlyRootFilesystem" : null,
        "dockerLabels" : null,
        "systemControls" : null,
        "privileged" : null
      }
    ]
  )
}

resource "aws_ecs_service" "Snyk_Broker_Ecs_Service" {
  name                               = "${var.nameprefix}-${var.task_name}"
  cluster                            = var.ECS_Cluster_Name
  task_definition                    = aws_ecs_task_definition.task_definition.arn
  desired_count                      = 1
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0
  launch_type                        = "FARGATE"
  propagate_tags                     = "TASK_DEFINITION"
  wait_for_steady_state              = var.wait_for_steady_state

  network_configuration {
    subnets          = var.FARGATE_Subnets
    security_groups  = setunion(var.FARGATE_SG, [aws_security_group.FARGATE_SecurityGroup.id])
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "${var.nameprefix}-${var.task_name}"
    container_port   = 8000
  }
}
