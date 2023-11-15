locals {
  subnets = {
    "public"  = ["10.0.1", "10.0.2", "10.0.3"]
    "private" = ["10.0.4", "10.0.5", "10.0.6"]
  }
  availability_zones = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
}

// creating the vpc
resource "aws_vpc" "eks_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"

  tags = {
    Name = "eks_vpc"
  }
}

//creating the subnets
resource "aws_subnet" "public_Subnet" {
  count                   = length(local.subnets.public)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "${element(local.subnets["public"], count.index)}.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name                                = " Public_Subnet"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/eks_cluster" = "owned"
  }
}

resource "aws_subnet" "private_Subnet" {
  count                   = length(local.subnets.private)
  vpc_id                  = aws_vpc.eks_vpc.id
  cidr_block              = "${element(local.subnets["private"], count.index)}.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name                                = " Private_Subnet"
    "kubernetes.io/role/internal-elb"   = "1"
    "kubernetes.io/cluster/eks_cluster" = "owned"
  }
}

// Routing for public subnet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "Internet_gateway"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "Public_route_table"
  }
}

resource "aws_route" "vpc_internet_access" {
  route_table_id         = aws_route_table.public_route_table.id
  gateway_id             = aws_internet_gateway.internet_gateway.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "vpc_association" {
  count          = length(local.subnets.public)
  depends_on     = [aws_route_table.public_route_table]
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = element(aws_subnet.public_Subnet.*.id, count.index)
}

// Routing for private subnet
resource "aws_eip" "eip" {
  count = length(local.subnets.public)
  public_ipv4_pool = "amazon"
  tags = {
    Name = "Private_route_table-${element(aws_subnet.private_Subnet.*.id, count.index)}"
  }
}

resource "aws_nat_gateway" "public_nat_gateway" {
  depends_on = [
    aws_eip.eip,
    aws_internet_gateway.internet_gateway
  ]
  count         = length(local.subnets.public)
  allocation_id = aws_eip.eip[count.index].id
  subnet_id     = element(aws_subnet.public_Subnet.*.id, count.index)
  tags = {
    Name = "Nat_gateway"
  }
}

resource "aws_route_table" "private_route_table" {
  count = length(local.subnets.public)
  depends_on = [
    aws_nat_gateway.public_nat_gateway,
    aws_subnet.private_Subnet
  ]
  vpc_id = aws_vpc.eks_vpc.id
  tags = {
    Name = "Private_route_table-${element(aws_subnet.private_Subnet.*.id, count.index)}"
  }
}

resource "aws_route" "nat_access" {
  count = length(local.subnets.public)
  depends_on = [
    aws_route_table.private_route_table,
    aws_nat_gateway.public_nat_gateway
  ]
  route_table_id         = element(aws_route_table.private_route_table.*.id, count.index)
  gateway_id             = element(aws_nat_gateway.public_nat_gateway.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table_association" "private_subnet_association" {
  count = length(local.subnets.public)
  depends_on = [
    aws_route_table.private_route_table,
    aws_nat_gateway.public_nat_gateway,
    aws_route.nat_access
  ]
  route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
  subnet_id      = element(aws_subnet.private_Subnet.*.id, count.index)
}
