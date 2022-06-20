# Create VPC
resource "aws_vpc" "vpc" {
  # checkov:skip=CKV2_AWS_12: All traffic restricted from within the security group
  # checkov:skip=CKV2_AWS_1: Separate NACLs will be create per subnet group
  cidr_block                       = var.cidr_block
  enable_dns_support               = var.enable_dns_support
  enable_dns_hostnames             = var.enable_dns_hostnames
  instance_tenancy                 = var.instance_tenancy
  assign_generated_ipv6_cidr_block = var.assign_ipv6_cidr_block

  tags = merge({
    Name = var.network_name
  }, var.tags)
}

resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id
}

locals {
  vpc_mask = element(split("/", var.cidr_block), 1)
}

# Create public subnet
resource "aws_subnet" "pub_sub" {
  # checkov:skip=CKV_AWS_130: Public IP required in public subnet
  count                   = length(var.azs)
  vpc_id                  = aws_vpc.vpc.id
  map_public_ip_on_launch = var.map_public_ip_for_public_subnet
  cidr_block = cidrsubnet(
    var.cidr_block,
    var.pub_subnet_mask - local.vpc_mask,
    count.index,
  )
  availability_zone = element(var.azs, count.index)

  tags = merge({
    Name = "${var.network_name}-pub-sub-${element(var.azs, count.index)}"
    Tier = "public"
  }, var.tags, var.add_eks_tags ? { "kubernetes.io/role/elb" : "1" } : {})
}

# Create private subnet
resource "aws_subnet" "pvt_sub" {
  count  = length(var.azs)
  vpc_id = aws_vpc.vpc.id
  cidr_block = cidrsubnet(
    var.cidr_block,
    var.pub_subnet_mask - local.vpc_mask,
    count.index + length(var.azs),
  )
  availability_zone = element(var.azs, count.index)

  tags = merge({
    Name = "${var.network_name}-pvt-sub-${element(var.azs, count.index)}"
    Tier = "private"
  }, var.tags, var.add_eks_tags ? { "kubernetes.io/role/internal-elb" : "1" } : {})
}

# Create internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-igw"
  }, var.tags)
}

# Create public route table
resource "aws_route_table" "pub_rtb" {
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-pub-rtb"
  }, var.tags)
}

resource "aws_route" "pub_rtb" {
  route_table_id         = aws_route_table.pub_rtb.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "pub_rtb_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.pub_sub[count.index].id
  route_table_id = aws_route_table.pub_rtb.id
}

# Create EIP for NAT gateway
resource "aws_eip" "nat_eip" {
  # checkov:skip=CKV2_AWS_19: EIP associated to NAT Gateway
  count = var.create_nat ? 1 : 0
  vpc   = true

  tags = merge({
    Name = "${var.network_name}-eip"
  }, var.tags)
}

# Create NAT gateway for private subnet
resource "aws_nat_gateway" "nat_gw" {
  count         = var.create_nat ? 1 : 0
  subnet_id     = aws_subnet.pub_sub[0].id
  allocation_id = join(", ", aws_eip.nat_eip.*.id)

  tags = merge({
    Name = "${var.network_name}-nat-gw"
  }, var.tags)
}

# Create private route table
resource "aws_route_table" "pvt_rtb" {
  count  = var.create_nat ? 0 : 1
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-pvt-rtb"
  }, var.tags)
}

resource "aws_route_table" "pvt_nat_rtb" {
  count  = var.create_nat ? 1 : 0
  vpc_id = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-pvt-nat-rtb"
  }, var.tags)
}

resource "aws_route" "pvt_nat_rtb" {
  count                  = var.create_nat ? 1 : 0
  route_table_id         = join(",", aws_route_table.pvt_nat_rtb.*.id)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = join(", ", aws_nat_gateway.nat_gw.*.id)
}

resource "aws_route_table_association" "pvt_rtb_assoc" {
  count          = length(var.azs)
  subnet_id      = aws_subnet.pvt_sub[count.index].id
  route_table_id = var.create_nat ? join(", ", aws_route_table.pvt_nat_rtb.*.id) : join(", ", aws_route_table.pvt_rtb.*.id)
}

# Create public NACL
resource "aws_network_acl" "pub_nacl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.pub_sub.*.id
  ingress    = var.pub_nacl_ingress
  egress     = var.pub_nacl_egress

  tags = merge({
    Name = "${var.network_name}-pub-nacl"
  }, var.tags)
}

# Create private NACL
resource "aws_network_acl" "pvt_nacl" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.pvt_sub.*.id
  ingress    = var.pvt_nacl_ingress
  egress     = var.pvt_nacl_egress

  tags = merge({
    Name = "${var.network_name}-pvt-nacl"
  }, var.tags)
}

# Restrict default security group to deny all traffic
resource "aws_default_security_group" "default" {
  # checkov:skip=CKV2_AWS_5: Attaching this security group to a resource depends on user
  vpc_id = aws_vpc.vpc.id
}

# Create private security group
resource "aws_security_group" "pvt_sg" {
  # checkov:skip=CKV2_AWS_5: Attaching this security group to a resource depends on user
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-private-sg"
  description = "Security group allowing communication within the VPC for ingress"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
    description = "Allow all traffic internally"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic externally"
  }

  tags = merge({
    Name = "${var.network_name}-private-sg"
  }, var.tags)
}

# Create protected security group for all communications strictly within the VPC
resource "aws_security_group" "protected_sg" {
  # checkov:skip=CKV2_AWS_5: Attaching this security group to a resource depends on user
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-protected-sg"
  description = "Security group allowing all communications strictly within the VPC"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
    description = "Allow all traffic internally"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
    description = "Allow all traffic externally"
  }

  tags = merge({
    Name = "${var.network_name}-protected-sg"
  }, var.tags)
}

# Create security group for public facing web servers or load balancer
resource "aws_security_group" "pub_sg" {
  # checkov:skip=CKV2_AWS_5: Attaching this security group to a resource depends on user
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-pub-web-sg"
  description = "Security group allowing 80 and 443 from outer world"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow http traffic from everywhere"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow https traffic from everywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic externally"
  }

  tags = merge({
    Name = "${var.network_name}-pub-web-sg"
  }, var.tags)
}

# Create security group for internal web/app servers
resource "aws_security_group" "pvt_web_sg" {
  # checkov:skip=CKV2_AWS_5: Attaching this security group to a resource depends on user
  count       = var.create_sgs ? 1 : 0
  vpc_id      = aws_vpc.vpc.id
  name        = "${var.network_name}-pvt-web-sg"
  description = "Security group allowing 80 and 443 internally for app servers"

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = aws_security_group.pub_sg.*.id
    description     = "Allow http traffic from public server security group"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = aws_security_group.pub_sg.*.id
    description     = "Allow https traffic from public server security group"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all traffic externally"
  }

  tags = merge({
    Name = "${var.network_name}-pvt-web-sg"
  }, var.tags)
}

# Create VPC flow logs
resource "aws_flow_log" "flow_logs" {
  count                = var.create_flow_logs ? 1 : 0
  iam_role_arn         = var.flow_logs_destination == "cloud-watch-logs" ? aws_iam_role.flow_logs_role[0].arn : ""
  log_destination      = var.flow_logs_destination == "cloud-watch-logs" ? aws_cloudwatch_log_group.cw_log_group[0].arn : aws_s3_bucket.flow_logs_bucket[0].arn
  log_destination_type = var.flow_logs_destination
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.vpc.id

  tags = merge({
    Name = "${var.network_name}-flow-logs"
  }, var.tags)
}

# Create cloudwatch log group for vpc flow logs
resource "aws_cloudwatch_log_group" "cw_log_group" {
  count             = var.create_flow_logs && var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? 1 : 0
  name              = "${var.network_name}-flow-logs-group"
  retention_in_days = var.flow_logs_retention
  kms_key_id        = var.cw_log_group_kms_key_arn

  tags = merge({
    Name = "${var.network_name}-flow-logs-group"
  }, var.tags)
}

# Create IAM role for VPC flow logs
resource "aws_iam_role" "flow_logs_role" {
  count = var.create_flow_logs && var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? 1 : 0
  name  = "${var.network_name}-flow-logs-role"

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

  tags = merge({
    Name = "${var.network_name}-flow-logs-role"
  }, var.tags)
}

# Create IAM policy for VPC flow logs role
resource "aws_iam_role_policy" "flow_logs_policy" {
  count = var.create_flow_logs && var.flow_logs_destination == "cloud-watch-logs" && var.flow_logs_cw_log_group_arn == "" ? 1 : 0
  name  = "${var.network_name}-flow-logs-policy"
  role  = aws_iam_role.flow_logs_role[0].id

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

data "aws_kms_key" "s3" {
  key_id = var.s3_kms_key
}

# Create S3 bucket for flow logs storage
resource "aws_s3_bucket" "flow_logs_bucket" {
  # checkov:skip=CKV_AWS_19: Default SSE is in place
  # checkov:skip=CKV_AWS_18: Access logging not required
  # checkov:skip=CKV_AWS_144: CRR not required
  # checkov:skip=CKV_AWS_145: Default SSE is in place
  # checkov:skip=CKV_AWS_52: MFA delete not required
  # checkov:skip=CKV_AWS_21: Versioning not required
  count         = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket        = "${var.network_name}-flow-logs-${random_id.id.hex}"
  force_destroy = var.s3_force_destroy

  tags = merge({
    Name = "${var.network_name}-flow-logs-${random_id.id.hex}"
  }, var.tags)
}

resource "aws_s3_bucket_acl" "flow_logs_bucket" {
  count  = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket = join(",", aws_s3_bucket.flow_logs_bucket.*.id)
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "flow_logs_bucket" {
  count  = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket = join(",", aws_s3_bucket.flow_logs_bucket.*.id)

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_kms_key == "alias/aws/s3" ? "AES256" : "aws:kms"
      kms_master_key_id = var.s3_kms_key == "alias/aws/s3" ? null : data.aws_kms_key.s3.id
    }
  }
}

data "aws_iam_policy_document" "flow_logs_bucket" {
  count = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    resources = [
      join(",", aws_s3_bucket.flow_logs_bucket.*.id),
      "${join(",", aws_s3_bucket.flow_logs_bucket.*.id)}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "flow_logs_bucket" {
  count  = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket = join(",", aws_s3_bucket.flow_logs_bucket.*.id)
  policy = join(",", data.aws_iam_policy_document.flow_logs_bucket.*.json)
}

resource "aws_s3_bucket_public_access_block" "flow_logs_bucket" {
  count                   = var.create_flow_logs && var.flow_logs_destination == "s3" && var.flow_logs_bucket_arn == "" ? 1 : 0
  bucket                  = join(",", aws_s3_bucket.flow_logs_bucket.*.id)
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create private hosted zone
resource "aws_route53_zone" "private" {
  count = var.create_private_zone == true ? 1 : 0
  name  = var.private_zone_domain

  vpc {
    vpc_id = aws_vpc.vpc.id
  }

  tags = merge({
    Name = "${var.network_name}-pvt-zone"
  }, var.tags)
}
