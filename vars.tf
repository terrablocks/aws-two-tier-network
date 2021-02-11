variable "cidr_block" {
  default = "10.0.0.0/16"
}

variable "network_name" {}

variable "azs" {
  type = list(string)
  default = [
    "us-east-1a",
    "us-east-1b",
  ]
}

variable "pub_subnet_mask" {
  default = "24"
}

variable "pvt_subnet_mask" {
  default = "24"
}

variable "create_nat" {
  default = true
}

variable "create_flow_logs" {
  default = true
}

variable "flow_logs_destination" {
  default = "cloud-watch-logs"
}

variable "create_private_zone" {
  default = false
}

variable "private_zone_domain" {
  default = "server.internal.com"
}

variable "create_sgs" {
  default = true
}

variable "tags" {
  type = map
  default = {}
}

variable "add_eks_tags" {
  default = false
}
