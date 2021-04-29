output "id" {
  value       = aws_vpc.vpc.id
  description = "ID of VPC created"
}

output "cidr" {
  value       = aws_vpc.vpc.cidr_block
  description = "CIDR block of VPC created"
}

output "public_subnet_ids" {
  value       = aws_subnet.pub_sub.*.id
  description = "List of public subnets id"
}

output "public_subnet_cidrs" {
  value       = aws_subnet.pub_sub.*.cidr_block
  description = "List of public subnet CIDR block"
}

output "public_subnet_rtb" {
  value       = aws_route_table.pub_rtb.id
  description = "ID of public route table created"
}

output "private_subnet_ids" {
  value       = aws_subnet.pvt_sub.*.id
  description = "List of private subnet id"
}

output "private_subnet_cidrs" {
  value       = var.create_nat ? join(",", aws_route_table.pvt_nat_rtb.*.id) : join(",", aws_route_table.pvt_rtb.*.id)
  description = "List of private subnet CIDR block"
}

output "private_subnet_rtb" {
  value       = var.create_nat ? join(",", aws_route_table.pvt_nat_rtb.*.id) : join(",", aws_route_table.pvt_rtb.*.id)
  description = "ID of private route table created"
}

output "nat_public_ip" {
  value       = var.create_nat ? join(", ", aws_nat_gateway.nat_gw.*.public_ip) : null
  description = "Elastic IP of NAT gateway"
}

output "pvt_sg" {
  value       = var.create_sgs ? join(", ", aws_security_group.pvt_sg.*.id) : null
  description = "ID of private security group"
}

output "protected_sg" {
  value       = var.create_sgs ? join(", ", aws_security_group.protected_sg.*.id) : null
  description = "ID of security group allowing all communications strictly within the VPC"
}

output "public_web_dmz_sg" {
  value       = var.create_sgs ? join(", ", aws_security_group.pub_sg.*.id) : null
  description = "Security group ID for public facing web servers or load balancer"
}

output "private_web_dmz_sg" {
  value       = var.create_sgs ? join(", ", aws_security_group.pvt_sg.*.id) : null
  description = "Security group ID for internal web/app servers"
}

output "private_zone_id" {
  value       = var.create_private_zone ? join(", ", aws_route53_zone.private.*.zone_id) : null
  description = "Route53 private hosted zone id"
}

output "private_zone_ns" {
  value       = var.create_private_zone ? aws_route53_zone.private.*.name_servers : null
  description = "List of private hosted zone name servers"
}
