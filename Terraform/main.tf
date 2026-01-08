resource "aws_vpc" "cloudzenia_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "cloudzenia-vpc"
  }
}

resource "aws_internet_gateway" "cloudzenia_igw" {
  vpc_id = aws_vpc.cloudzenia_vpc.id

  tags = {
    Name = "cloudzenia-igw"
  }
}

resource "aws_subnet" "cloudzenia_public_1" {
  vpc_id                  = aws_vpc.cloudzenia_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudzenia-public-subnet-1"
  }
}

resource "aws_subnet" "cloudzenia_public_2" {
  vpc_id                  = aws_vpc.cloudzenia_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudzenia-public-subnet-2"
  }
}

resource "aws_subnet" "cloudzenia_private_1" {
  vpc_id            = aws_vpc.cloudzenia_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "cloudzenia-private-subnet-1"
  }
}

resource "aws_subnet" "cloudzenia_private_2" {
  vpc_id            = aws_vpc.cloudzenia_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "cloudzenia-private-subnet-2"
  }
}

resource "aws_eip" "cloudzenia_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "cloudzenia-nat-eip"
  }
}

resource "aws_nat_gateway" "cloudzenia_nat" {
  allocation_id = aws_eip.cloudzenia_nat_eip.id
  subnet_id     = aws_subnet.cloudzenia_public_1.id

  depends_on = [aws_internet_gateway.cloudzenia_igw]

  tags = {
    Name = "cloudzenia-nat-gateway"
  }
}

resource "aws_route_table" "cloudzenia_public_rt" {
  vpc_id = aws_vpc.cloudzenia_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cloudzenia_igw.id
  }

  tags = {
    Name = "cloudzenia-public-route-table"
  }
}

resource "aws_route_table" "cloudzenia_private_rt" {
  vpc_id = aws_vpc.cloudzenia_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.cloudzenia_nat.id
  }

  tags = {
    Name = "cloudzenia-private-route-table"
  }
}

resource "aws_route_table_association" "cloudzenia_public_1_assoc" {
  subnet_id      = aws_subnet.cloudzenia_public_1.id
  route_table_id = aws_route_table.cloudzenia_public_rt.id
}

resource "aws_route_table_association" "cloudzenia_public_2_assoc" {
  subnet_id      = aws_subnet.cloudzenia_public_2.id
  route_table_id = aws_route_table.cloudzenia_public_rt.id
}

resource "aws_route_table_association" "cloudzenia_private_1_assoc" {
  subnet_id      = aws_subnet.cloudzenia_private_1.id
  route_table_id = aws_route_table.cloudzenia_private_rt.id
}

resource "aws_route_table_association" "cloudzenia_private_2_assoc" {
  subnet_id      = aws_subnet.cloudzenia_private_2.id
  route_table_id = aws_route_table.cloudzenia_private_rt.id
}
