# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block = "${var.cidr_block}"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.network_name}"
  }
}

locals {
  vpc_mask = "${element(split("/", var.cidr_block), 1)}"
}

# Create public subnet
resource "aws_subnet" "pub_sub" {
  count = "${length(var.azs)}"
  vpc_id = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = true
  cidr_block = "${cidrsubnet(var.cidr_block, var.pub_subnet_mask - local.vpc_mask, count.index)}"
  availability_zone = "${element(var.azs, count.index)}"

  tags = {
    Name = "${var.network_name}-pub-sub-${element(var.azs, count.index)}"
    Tier = "public"
  }
}

# Create private subnet
resource "aws_subnet" "pvt_sub" {
  count = "${length(var.azs)}"
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "${cidrsubnet(var.cidr_block, var.pub_subnet_mask - local.vpc_mask, count.index + length(var.azs))}"
  availability_zone = "${element(var.azs, count.index)}"

  tags = {
    Name = "${var.network_name}-pvt-sub-${element(var.azs, count.index)}"
    Tier = "private"
  }
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags = {
    Name = "${var.network_name}-igw"
  }
}

# Create public route table
resource "aws_route_table" "pub_rtb" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table_association" "pub_rtb_assoc" {
  count = "${length(var.azs)}"
  subnet_id = "${aws_subnet.pub_sub[count.index].id}"
  route_table_id = "${aws_route_table.pub_rtb.id}"
}

# Create EIP for NAT gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

# Create NAT gateway for private subnet
resource "aws_nat_gateway" "nat_gw" {
  subnet_id = "${aws_subnet.pub_sub.0.id}"
  allocation_id = "${aws_eip.nat_eip.id}"

  tags = {
    Name = "${var.network_name}-nat-gw"
  }
}

# Create private route table
resource "aws_route_table" "pvt_rtb" {
  vpc_id = "${aws_vpc.vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }
}

resource "aws_route_table_association" "pvt_rtb_assoc" {
  count = "${length(var.azs)}"
  subnet_id = "${aws_subnet.pvt_sub[count.index].id}"
  route_table_id = "${aws_route_table.pvt_rtb.id}"
}

# Create public NACL
resource "aws_network_acl" "pub_nacl" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = "${aws_subnet.pub_sub.*.id}"

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

  egress {
    protocol   = "tcp"
    rule_no    = 200
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  egress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = "tcp"
    rule_no    = 999
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }

  tags = {
    Name = "${var.network_name}-pub-nacl"
  }
}

# Create private NACL
resource "aws_network_acl" "pvt_nacl" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = "${aws_subnet.pvt_sub.*.id}"

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "${var.network_name}-pvt-nacl"
  }
}

# Create security group for internal communication
resource "aws_security_group" "int_sg" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "${var.network_name}-internal-sg"
  description = "Security group allowing communication internally within the VPC"

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["${var.cidr_block}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for accepting only SSH connection
resource "aws_security_group" "ssh_sg" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "${var.network_name}-ssh-sg"
  description = "Security group allowing only SSH connections"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for public facing web servers or load balancer
resource "aws_security_group" "pub_sg" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "${var.network_name}-pub-web-sg"
  description = "Security group allowing 80 and 443 from outer world"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for internal web/app servers
resource "aws_security_group" "pvt_sg" {
  vpc_id = "${aws_vpc.vpc.id}"
  name = "${var.network_name}-pvt-web-sg"
  description = "Security group allowing 22, 80 and 443 internally for instances"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    security_groups = ["${aws_security_group.pub_sg.id}"]
  }

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = ["${aws_security_group.pub_sg.id}"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    security_groups = ["${aws_security_group.pub_sg.id}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create VPC flow logs
resource "aws_flow_log" "flow_logs" {
  iam_role_arn    = "${var.flow_logs_destination == "cloud-watch-logs" ? "${aws_iam_role.flow_logs_role.0.arn}" : ""}"
  log_destination = "${var.flow_logs_destination == "cloud-watch-logs" ? "${aws_cloudwatch_log_group.cw_log_group.0.arn}" : "${aws_s3_bucket.flow_logs_bucket.0.arn}"}"
  log_destination_type = "${var.flow_logs_destination}"
  traffic_type    = "ALL"
  vpc_id          = "${aws_vpc.vpc.id}"
}

# Create cloudwatch log group for vpc flow logs
resource "aws_cloudwatch_log_group" "cw_log_group" {
  count = "${var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0}"
  name = "${var.network_name}-flow-logs-group"
}

# Create IAM role for VPC flow logs
resource "aws_iam_role" "flow_logs_role" {
  count = "${var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0}"
  name = "${var.network_name}-flow-logs-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# Create IAM policy for VPC flow logs role
resource "aws_iam_role_policy" "flow_logs_policy" {
  count = "${var.flow_logs_destination == "cloud-watch-logs" ? 1 : 0}"
  name = "${var.network_name}-flow-logs-policy"
  role = "${aws_iam_role.flow_logs_role.0.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "random_id" "id" {
  byte_length = 8
}

# Create S3 bucket for flow logs storage
resource "aws_s3_bucket" "flow_logs_bucket" {
  count = "${var.flow_logs_destination == "cloud-watch-logs" ? 0 : 1}"
  bucket = "${var.network_name}-flow-logs-${random_id.id.hex}"
}

# Create private hosted zone
resource "aws_route53_zone" "private" {
  count = "${var.private_zone == true ? 1 : 0}"
  name = "${var.private_zone_domain}"

  vpc {
    vpc_id = "${aws_vpc.vpc.id}"
  }
}
