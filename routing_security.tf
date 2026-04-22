# Route Tables
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.lso_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lso_igw.id
  }
  tags = { Name = "LSO-RT-PUB-2A" }
}

resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.lso_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lso_nat.id
  }
  tags = { Name = "LSO-RT-PRI-2A" }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.web_pub.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "app_assoc" {
  subnet_id      = aws_subnet.app_pri.id
  route_table_id = aws_route_table.pri_rt.id
}

resource "aws_route_table_association" "db_assoc" {
  subnet_id      = aws_subnet.db_pri.id
  route_table_id = aws_route_table.pri_rt.id
}

resource "aws_route_table_association" "dummy_assoc" {
  subnet_id      = aws_subnet.dummy_pri.id
  route_table_id = aws_route_table.pri_rt.id
}

resource "aws_route_table_association" "pub_assoc_2c" {
  subnet_id      = aws_subnet.web_pub_2c.id
  route_table_id = aws_route_table.pub_rt.id
}

# Security Groups
resource "aws_security_group" "web_sg" {
  name   = "LSO-PUB-SG-2A"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name   = "LSO-PRI-APP-SG-2A"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "LSO-PRI-SG-DB-2A"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 보안 그룹(Security Groups) 영역에 ALB용 보안 그룹 추가
resource "aws_security_group" "alb_sg" {
  name   = "LSO-ALB-SG"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "LSO-ALB-SG" }
}