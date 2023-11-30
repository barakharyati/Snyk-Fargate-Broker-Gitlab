# Snyk-Gitlab-Fargate-TF-Module
## Module for deploying  Snyk Broker on ECS Fargate
Build Snyk Gitlab Broker on ECS Fargate including ALB, Security Groups and ECS Service. the Gitlab Token will be pulled from AWS SCM

## Required Variables:
| Variable Name | Variable Type | Variable description | default |
| ------------- | ------------- | -------------------- | ----- | 
| r53_zone |string | Route 53 zone for creating the domain record | |
| environment |string | Name refix for aws resource creation | |
| task_name | string | The ecs Task name will be inherit to Several resources - like Task definition , Service  etc. | |
| exe_task_ssm_secret | string | execution task aws secret manager arn  | | 
| registry_token_fargate_ssm_secret | string | gitlab registry access token aws secret manager arn| | 
| var_container_image |string |Snyk Container Image  | | 
| ECS_Cluster_Name | string | ecs cluster for deploying the ecs service| | 
| gitlabServer | string | the gitlab server dns to connect to | | 
| FARGATE_Subnets | set(string) | "Fargate Security Groups "  | []|
| FARGATE_SG | set(string) | list of Security groups to add Broker Fargate host to | [] |
| broker_port | number | Snyk broker port | 8000 |
| snyk_docker_cpu | number |  | 1024 |
| snyk_docker_memory | number |  | 2048 |
| fargate_SG_Ingress_Rules | set(object) | Fargate Host egress Rules - set(object({description=string,port= number,protocol=string, security_groups  = set(string),cidr_blocks  = set(string), ipv6_cidr_blocks set(string) } ) ) |  |
| ALB_SG_Ingress_Rules | set(object) | Broker ALB Ingress Rules - set(object({description=string,port= number,protocol=string, security_groups  = set(string),cidr_blocks  = set(string), ipv6_cidr_blocks set(string) } ) ) |  |
| certificate_arn | string | the certificate ARN (ACM) , if null the module will search for the zone wildcard certificate | ""|
