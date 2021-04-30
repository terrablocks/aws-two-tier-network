# Create a two tier AWS VPC network

![License](https://img.shields.io/github/license/terrablocks/aws-two-tier-network?style=for-the-badge) ![Checkov](https://img.shields.io/github/workflow/status/terrablocks/aws-two-tier-network/checkov/master?label=checkov&style=for-the-badge) ![Commit](https://img.shields.io/github/last-commit/terrablocks/aws-two-tier-network?style=for-the-badge)

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

# Usage Instructions
## Example
```terraform
module "vpc" {
  source = "github.com/terrablocks/aws-two-tier-network.git"

  network_name     = "pvt-network"
  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  pub_subnet_mask  = 24
  pvt_subnet_mask  = 22
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.13 |
| aws | 3.37.0 |
| random | 3.1.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cidr_block | CIDR block for VPC | `string` | `"10.0.0.0/16"` | no |
| network_name | Name to be used for VPC resources | `string` | n/a | yes |
| azs | List of availability zones to be used for launching resources | `list(string)` | <pre>[<br>  "us-east-1a",<br>  "us-east-1b"<br>]</pre> | no |
| pub_subnet_mask | Subnet mask to use for public subnet | `number` | `24` | no |
| pvt_subnet_mask | Subnet mask to use for private subnet | `number` | `24` | no |
| create_nat | Whether to create NAT gateway for private subnet | `bool` | `true` | no |
| create_flow_logs | Whether to enable flow logs for VPC | `bool` | `true` | no |
| flow_logs_destination | Destination to store VPC flow logs. Possible values: s3, cloud-watch-logs | `string` | `"cloud-watch-logs"` | no |
| flow_logs_retention | Time period for which you want to retain VPC flow logs in CloudWatch log group. Default is 0 which means logs never expire. Possible values are 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653 | `number` | `0` | no |
| s3_force_destroy | Delete bucket content before deleting bucket | `bool` | `true` | no |
| s3_kms_key | Alias/ID/ARN of KMS key to use for encrypting S3 bucket content | `string` | `"alias/aws/s3"` | no |
| create_private_zone | Whether to create private hosted zone for VPC | `bool` | `false` | no |
| private_zone_domain | Domain name to be used for private hosted zone | `string` | `"server.internal.com"` | no |
| create_sgs | Whether to create few additional security groups which are mostly required for controlling traffic | `bool` | `true` | no |
| tags | Map of key-value pair to associate with resources | `map(any)` | `{}` | no |
| add_eks_tags | Add `kubernetes.io/role/elb: 1` and `kubernetes.io/role/internal-elb: 1` tags to respective subnets for load balancer | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | ID of VPC created |
| cidr | CIDR block of VPC created |
| public_subnet_ids | List of public subnets id |
| public_subnet_cidrs | List of public subnet CIDR block |
| public_subnet_rtb | ID of public route table created |
| private_subnet_ids | List of private subnet id |
| private_subnet_cidrs | List of private subnet CIDR block |
| private_subnet_rtb | ID of private route table created |
| nat_public_ip | Elastic IP of NAT gateway |
| pvt_sg | ID of private security group |
| protected_sg | ID of security group allowing all communications strictly within the VPC |
| public_web_dmz_sg | Security group ID for public facing web servers or load balancer |
| private_web_dmz_sg | Security group ID for internal web/app servers |
| private_zone_id | Route53 private hosted zone id |
| private_zone_ns | List of private hosted zone name servers |
