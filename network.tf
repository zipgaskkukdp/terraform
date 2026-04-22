resource "aws_vpc" "lso_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "LSO-VPC" }
}

resource "aws_internet_gateway" "lso_igw" {
  vpc_id = aws_vpc.lso_vpc.id
  tags   = { Name = "LSO-IGW" }
}

resource "aws_eip" "nat_eip" {
  domain = "vpc"
  tags   = { Name = "LSO-NAT-EIP" }
}

resource "aws_nat_gateway" "lso_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.web_pub.id
  tags          = { Name = "LSO-NGW-2A" }
}

resource "aws_subnet" "web_pub" {
  vpc_id            = aws_vpc.lso_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "LSO-WEB-PUB-2A" }
}

# network.tf 하단에 추가 ALB를 위한 가용영역 추가
resource "aws_subnet" "web_pub_2c" {
  vpc_id            = aws_vpc.lso_vpc.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "LSO-WEB-PUB-2C" }
}

resource "aws_subnet" "app_pri" {
  vpc_id            = aws_vpc.lso_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "LSO-APP-PRI-2A" }
}

resource "aws_subnet" "db_pri" {
  vpc_id            = aws_vpc.lso_vpc.id
  cidr_block        = "10.0.12.0/24"
  availability_zone = "ap-northeast-2a"
  tags              = { Name = "LSO-DB-PRI-2A" }
}

resource "aws_subnet" "dummy_pri" {
  vpc_id            = aws_vpc.lso_vpc.id
  cidr_block        = "10.0.50.0/24"
  availability_zone = "ap-northeast-2c"
  tags              = { Name = "DUMMY-PRI-2C" }
}
