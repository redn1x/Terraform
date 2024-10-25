# Actual VPC

resource "aws_vpc" "default" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = "${merge(var.tags, map("Name", "${var.name}"))}"
}

# Default security group

resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags   = "${merge(var.tags, map("Name", "${var.name}-default"))}"
}

# Default route table

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.default.default_route_table_id}"
  tags                   = "${merge(var.tags, map("Name", "${var.name}-default"))}"
}

# Default network ACLs

resource "aws_default_network_acl" "default" {
  default_network_acl_id = "${aws_vpc.default.default_network_acl_id}"
  subnet_ids             = "${concat(aws_subnet.public.*.id, aws_subnet.private.*.id, aws_subnet.internal.*.id)}"

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-default"))}"
}

data "aws_region" "current" {}

resource "aws_vpc_dhcp_options" "default" {
  domain_name         = "${data.aws_region.current.name != "us-east-1" ? "${data.aws_region.current.name}.compute" : "ec2"}.internal"
  domain_name_servers = ["AmazonProvidedDNS"]
  ntp_servers         = ["169.254.169.123"]

  tags = "${merge(var.tags, map("Name", "${var.name}-dhcp-options"))}"
}

resource "aws_vpc_dhcp_options_association" "default" {
  vpc_id          = "${aws_vpc.default.id}"
  dhcp_options_id = "${aws_vpc_dhcp_options.default.id}"
}

# Public subnet (each AZ)

resource "aws_subnet" "public" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.default.id}"
  availability_zone = "${var.availability_zones[count.index]}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr_block, var.subnet_block_size, count.index * 4)}"

  tags = "${merge(var.tags, map("Name", "${var.name}-public-${var.availability_zones[count.index]}"))}"
}

# Private subnet (each AZ)

resource "aws_subnet" "private" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.default.id}"
  availability_zone = "${var.availability_zones[count.index]}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr_block, var.subnet_block_size, (count.index * 4) + 1)}"

  tags = "${merge(var.tags, map("Name", "${var.name}-private-${var.availability_zones[count.index]}"))}"
}

# Internal subnet (each AZ) - has no NAT gateway access

resource "aws_subnet" "internal" {
  count             = "${length(var.availability_zones)}"
  vpc_id            = "${aws_vpc.default.id}"
  availability_zone = "${var.availability_zones[count.index]}"
  cidr_block        = "${cidrsubnet(var.vpc_cidr_block, var.subnet_block_size, (count.index * 4) + 2)}"

  tags = "${merge(var.tags, map("Name", "${var.name}-internal-${var.availability_zones[count.index]}"))}"
}

# Internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(var.tags, map("Name", "${var.name}-gateway"))}"
}

# Public route table

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }

  tags = "${merge(var.tags, map("Name", "${var.name}-public"))}"
}

# Public route table associations (each AZ)

resource "aws_route_table_association" "public" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

# NAT gateway

resource "aws_eip" "nat" {
  count      = "${length(var.availability_zones)}"
  depends_on = ["aws_internet_gateway.gw"]
  vpc        = true

  tags = "${merge(var.tags, map("Name", "${var.name}-nat-${var.availability_zones[count.index]}"))}"
}

resource "aws_nat_gateway" "nat" {
  count         = "${length(var.availability_zones)}"
  depends_on    = ["aws_internet_gateway.gw"]
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"

  tags = "${merge(var.tags, map("Name", "${var.name}-nat-${var.availability_zones[count.index]}"))}"
}

# Private route table

resource "aws_route_table" "private" {
  count  = "${length(var.availability_zones)}"
  vpc_id = "${aws_vpc.default.id}"

  tags = "${merge(var.tags, map("Name", "${var.name}-private-${var.availability_zones[count.index]}"))}"
}

resource "aws_route" "private" {
  count                  = "${length(var.availability_zones)}"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, count.index)}"
}

# Private route table associations (each AZ)

resource "aws_route_table_association" "private" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}

# Internal route table associations (each AZ)

resource "aws_route_table_association" "internal" {
  count          = "${length(var.availability_zones)}"
  subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
  route_table_id = "${aws_default_route_table.default.id}"
}

# Flow log

resource "aws_flow_log" "flow_log" {
  log_destination = "${aws_cloudwatch_log_group.flow_log.arn}"
  iam_role_arn    = "${aws_iam_role.flow_log.arn}"
  vpc_id          = "${aws_vpc.default.id}"
  traffic_type    = "ALL"
}