# Create a two tier AWS VPC network

This terraform module will deploy the following services:
- VPC
  - Subnets
  - Internet Gateway
  - NAT Gateway
  - Route Tables
  - NACLs
  - Security Groups
  - Flow Logs
- Route53
  - Private Hosted Zone
- CloudWatch
  - Log Group
- S3

# Usage Instructions:
## Variables
| Parameter             | Type    | Description                                                               | Default                      | Required |
|-----------------------|---------|---------------------------------------------------------------------------|------------------------------|----------|
| cidr_block            | string  | CIDR block for VPC                                                        | 10.0.0.0/16                  | N        |
| network_name          | string  | Name to be used for VPC resources                                         |                              | Y        |
| azs                   | list    | List of availability zones to be used for launching resources             | ["us-east-1a", "us-east-1b"] | N        |
| pub_subnet_mask       | string  | Subnet mask to use for public subnet                                      | 24                           | N        |
| pvt_subnet_mask       | string  | Subnet mask to use for private subnet                                     | 24                           | N        |
| flow_logs_destination | string  | Destination to store VPC flow logs. Possible values: s3, cloud-watch-logs | cloud-watch-logs             | N        |
| private_zone          | boolean | Whether to create private hosted zone for VPC                             | false                        | N        |
| private_zone_domain   | string  | Domain name to be used for private hosted zone                            | server.internal.com          | N        |

## Outputs
| Parameter            | Type   | Description                                                      |
|----------------------|--------|------------------------------------------------------------------|
| vpc_id               | string | ID of VPC created                                                |
| public_subnet_id     | list   | ID of public subnet(s) created                                   |
| public_subnet_cidrs  | list   | CIDR block of public subnet(s) created                           |
| private_subnet_id    | list   | ID of private subnet(s) created                                  |
| private_subnet_cidrs | list   | CIDR block of private subnet(s) created                          |
| nat_public_ip        | string | Elastic IP of NAT gateway                                        |
| internal_sg          | string | Security group ID for internal communication                     |
| ssh_only_sg          | string | Security group ID for accepting only SSH connection              |
| public_web_dmz_sg    | string | Security group ID for public facing web servers or load balancer |
| private_web_dmz_sg   | string | Security group ID for internal web/app servers                   |
| private_zone_id      | string | Route53 private hosted zone id                                   |
| private_zone_ns      | list   | List of private hosted zone name servers                         |

## Deployment
- `terraform init` - download plugins required to deploy resources
- `terraform plan` - get detailed view of resources that will be created, deleted or replaced
- `terraform apply -auto-approve` - deploy the template without confirmation (non-interactive mode)
- `terraform destroy -auto-approve` - terminate all the resources created using this template without confirmation (non-interactive mode)
