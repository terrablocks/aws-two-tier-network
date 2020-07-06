output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.pub_sub.*.id
}

output "public_subnet_cidrs" {
  value = aws_subnet.pub_sub.*.cidr_block
}

output "private_subnet_id" {
  value = aws_subnet.pvt_sub.*.id
}

output "private_subnet_cidrs" {
  value = aws_subnet.pvt_sub.*.cidr_block
}

output "nat_public_ip" {
  value = join(", ", aws_nat_gateway.nat_gw.*.public_ip) == "" ? null : join(", ", aws_nat_gateway.nat_gw.*.public_ip)
}

output "internal_sg" {
  value = join(", ", aws_security_group.int_sg.*.id) == "" ? null : join(", ", aws_security_group.int_sg.*.id)
}

output "ssh_only_sg" {
  value = join(", ", aws_security_group.ssh_sg.*.id) == "" ? null : join(", ", aws_security_group.ssh_sg.*.id)
}

output "public_web_dmz_sg" {
  value = join(", ", aws_security_group.pub_sg.*.id) == "" ? null : join(", ", aws_security_group.pub_sg.*.id)
}

output "private_web_dmz_sg" {
  value = join(", ", aws_security_group.pvt_sg.*.id) == "" ? null : join(", ", aws_security_group.pvt_sg.*.id)
}

output "private_zone_id" {
  value = join(", ", aws_route53_zone.private.*.zone_id) == "" ? null : join(", ", aws_route53_zone.private.*.zone_id)
}

output "private_zone_ns" {
  value = length(aws_route53_zone.private.*.name_servers) == 0 ? null : aws_route53_zone.private.*.name_servers
}
