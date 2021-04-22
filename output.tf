output "id" {
  value = aws_vpc.vpc.id
}

output "cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "public_subnet_ids" {
  value = aws_subnet.pub_sub.*.id
}

output "public_subnet_cidrs" {
  value = aws_subnet.pub_sub.*.cidr_block
}

output "public_subnet_rtb" {
  value = aws_route_table.pub_rtb.id
}

output "private_subnet_ids" {
  value = aws_subnet.pvt_sub.*.id
}

output "private_subnet_cidrs" {
  value = var.create_pvt_nat ? join(",", aws_route_table.pvt_nat_rtb.*.id) : join(",", aws_route_table.pvt_rtb.*.id)
}

output "private_subnet_rtb" {
  value = var.create_pvt_nat ? aws_route_table.pvt_nat_rtb.id : aws_route_table.pvt_rtb.id
}

output "nat_public_ip" {
  value = var.create_nat ? join(", ", aws_nat_gateway.nat_gw.*.public_ip) : null
}

output "internal_sg" {
  value = var.create_sgs ? join(", ", aws_security_group.int_sg.*.id) : null
}

output "ssh_only_sg" {
  value = var.create_sgs ? join(", ", aws_security_group.ssh_sg.*.id) : null
}

output "public_web_dmz_sg" {
  value = var.create_sgs ? join(", ", aws_security_group.pub_sg.*.id) : null
}

output "private_web_dmz_sg" {
  value = var.create_sgs ? join(", ", aws_security_group.pvt_sg.*.id) : null
}

output "private_zone_id" {
  value = var.create_private_zone ? join(", ", aws_route53_zone.private.*.zone_id) : null
}

output "private_zone_ns" {
  value = var.create_private_zone ? aws_route53_zone.private.*.name_servers : null
}
