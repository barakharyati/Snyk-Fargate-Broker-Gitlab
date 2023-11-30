variable "aws_region" {
  type        = string
  description = "aws region for the broker deployment"
}
variable "r53_zone" {
  description = "Route 53 zone for creating the domain record"
  type        = string
}
variable "task_name" {
  type        = string
  description = "The ecs Task name will be inherit to Several resources - like Task definition , Service  etc."
}

variable "exe_task_ssm_secret" {
  type        = string
  description = "Execution task aws secret manager arn"
}

variable "registry_token_fargate_ssm_secret" {
  type        = string
  description = "gitlab registry access token aws secret manager arn|"
}

variable "var_container_image" {
  type        = string
  description = "Snyk Container Image"
  #default = "snyk/broker:gitlab"
}

variable "ECS_Cluster_Name" {
  type        = string
  description = "ecs cluster for deploying the ecs service"
}

variable "gitlabServer" {
  type        = string
  description = "the gitlab server dns to connect to"
}

variable "FARGATE_Subnets" {
  type        = set(string)
  default     = []
  description = "Fargate Security Groups "
}
variable "FARGATE_SG" {
  type        = set(string)
  default     = []
  description = "list of Security groups to add Broker Fargate host to"
}
variable "broker_port" {
  type    = number
  default = 8000
}

variable "snyk_docker_cpu" {
  type    = number
  default = 1024
}

variable "snyk_docker_memory" {
  type    = number
  default = 2048
}

variable "fargate_SG_Ingress_Rules" {
  type = set(object({
    description      = string
    port             = number
    protocol         = string
    security_groups  = set(string)
    cidr_blocks      = set(string)
    ipv6_cidr_blocks = set(string)

  }))
  description = "the Fargate Host Ingress Rules"
}

variable "Fargate_SG_egress_rules" {
  type = set(object({
    description      = string
    port             = number
    protocol         = string
    security_groups  = set(string)
    cidr_blocks      = set(string)
    ipv6_cidr_blocks = set(string)
  }))
  description = "Fargate Host egress Rules"
}

variable "ALB_SG_Ingress_Rules" {
  type = set(object({
    description      = string
    port             = number
    protocol         = string
    security_groups  = set(string)
    cidr_blocks      = set(string)
    ipv6_cidr_blocks = set(string)
  }))
  description = "Broker ALB Ingress Rules"
}

variable "certificate_arn" {
  type        = string
  description = "the certificate ARN (ACM) , if null the module will search for the zone wildcard certificate"
  default     = ""
}

variable "wait_for_steady_state" {
  default = true
}

variable "nameprefix" {
  description = "prefix for aws resource creation"
  default     = ""
  type        = string
}

