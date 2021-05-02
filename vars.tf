variable "cidr_block" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR block for VPC"
}

variable "network_name" {
  type        = string
  description = "Name to be used for VPC resources"
}

variable "azs" {
  type = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
  ]
  description = "List of availability zones to be used for launching resources"
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
