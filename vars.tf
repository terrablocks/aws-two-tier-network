variable "network_name" {
  type        = string
  description = "Name to be used for VPC resources"
}

variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "additional_cidr_blocks" {
  type        = list(string)
  default     = []
  description = "Additional CIDR block to assicate with VPC"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "Whether to enable/disable DNS support in the VPC"
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "Whether to enable/disable DNS hostnames in the VPC"
}

variable "instance_tenancy" {
  type        = string
  default     = "default"
  description = "Tenancy option for instances launched into the VPC. **Valid values:** default, dedicated"
}

variable "assign_ipv6_cidr_block" {
  type        = bool
  default     = false
  description = "Requests an Amazon-provided IPv6 CIDR block with a /56 prefix length for the VPC"
}

variable "azs" {
  type = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
  ]
  description = "List of availability zones to be used for launching resources"
}

variable "map_public_ip_for_public_subnet" {
  type        = bool
  default     = true
  description = "Auto assign public IP to resources launched in public subnet"
}

variable "pub_subnet_mask" {
  type        = number
  default     = 24
  description = "Subnet mask to use for public subnet"
}

variable "pvt_subnet_mask" {
  type        = number
  default     = 24
  description = "Subnet mask to use for private subnet"
}

variable "create_nat" {
  type        = bool
  default     = true
  description = "Whether to create NAT gateway for private subnet"
}

variable "nat_eip_id" {
  type        = string
  default     = ""
  description = "Allocation ID of EIP to attach to NAT gateway in private subnet. Leave it blank to create a new EIP"
}

variable "pub_nacl_ingress" {
  type = list(any)
  default = [
    {
      rule_no         = 100
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = null
      icmp_type       = null
      icmp_code       = null
      from_port       = 0
      to_port         = 0
      action          = "allow"
    }
  ]
  description = "List of ingress rules to attach to public subnet NACL"
}

variable "pub_nacl_egress" {
  type = list(any)
  default = [
    {
      rule_no         = 100
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = null
      icmp_type       = null
      icmp_code       = null
      from_port       = 0
      to_port         = 0
      action          = "allow"
    }
  ]
  description = "List of egress rules to attach to public subnet NACL"
}

variable "pvt_nacl_ingress" {
  type = list(any)
  default = [
    {
      rule_no         = 100
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = null
      icmp_type       = null
      icmp_code       = null
      from_port       = 0
      to_port         = 0
      action          = "allow"
    }
  ]
  description = "List of ingress rules to attach to private subnet NACL"
}

variable "pvt_nacl_egress" {
  type = list(any)
  default = [
    {
      rule_no         = 100
      protocol        = "-1"
      cidr_block      = "0.0.0.0/0"
      ipv6_cidr_block = null
      icmp_type       = null
      icmp_code       = null
      from_port       = 0
      to_port         = 0
      action          = "allow"
    }
  ]
  description = "List of egress rules to attach to private subnet NACL"
}

variable "create_flow_logs" {
  type        = bool
  default     = true
  description = "Whether to enable flow logs for VPC"
}

variable "flow_logs_destination" {
  type        = string
  default     = "cloud-watch-logs"
  description = "Destination to store VPC flow logs. Possible values: s3, cloud-watch-logs"
}

variable "flow_logs_retention" {
  type        = number
  default     = 0
  description = "Time period for which you want to retain VPC flow logs in CloudWatch log group. Default is 0 which means logs never expire. Possible values are 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653"
}

variable "flow_logs_cw_log_group_arn" {
  type        = string
  default     = ""
  description = "ARN of CloudWatch Log Group to use for storing VPC flow logs"
}

variable "cw_log_group_kms_key_arn" {
  type        = string
  default     = null
  description = "ARN of KMS key to use for Cloudwatch Log Group SSE"
}

variable "flow_logs_bucket_arn" {
  type        = string
  default     = ""
  description = "ARN of S3 to use for storing VPC flow logs"
}

variable "s3_force_destroy" {
  type        = bool
  default     = true
  description = "Delete bucket content before deleting bucket"
}

variable "s3_kms_key" {
  type        = string
  default     = "alias/aws/s3"
  description = "Alias/ID/ARN of KMS key to use for encrypting S3 bucket content"
}

variable "create_private_zone" {
  type        = bool
  default     = false
  description = "Whether to create private hosted zone for VPC"
}

variable "private_zone_domain" {
  type        = string
  default     = "server.internal.com"
  description = "Domain name to be used for private hosted zone"
}

variable "create_sgs" {
  type        = bool
  default     = true
  description = "Whether to create few additional security groups which are mostly required for controlling traffic"
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Map of key-value pair to associate with resources"
}

variable "add_eks_tags" {
  type        = bool
  default     = false
  description = "Add `kubernetes.io/role/elb: 1` and `kubernetes.io/role/internal-elb: 1` tags to respective subnets for load balancer"
}
