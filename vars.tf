variable "profile" {}
variable "region" {
    default = "us-east-1"
}
variable "cidr_block" {
    default = "10.0.0.0/16"
}
variable "network_name" {}
variable "azs" {
    type = "list"
    default = [
        "us-east-1a",
        "us-east-1b"
    ]
}
variable "pub_subnet_mask" {
    default = "24"
}
variable "pvt_subnet_mask" {
    default = "24"
}

variable "flow_logs_destination" {
    default = "cloud-watch-logs"
}

variable "private_zone" {
    default = false
}

variable "private_zone_domain" {
    default = "server.internal.com"
}
