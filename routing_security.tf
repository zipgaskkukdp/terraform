# --- Route Tables & Associations ---
resource "aws_route_table" "pub_rt" {
  vpc_id = aws_vpc.lso_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lso_igw.id
  }
  tags = { Name = "LSO-RT-PUB" }
}

resource "aws_route_table" "pri_rt" {
  vpc_id = aws_vpc.lso_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lso_nat.id
  }
  tags = { Name = "LSO-RT-PRI" }
}

resource "aws_route_table_association" "pub_assoc" {
  subnet_id      = aws_subnet.web_pub.id
  route_table_id = aws_route_table.pub_rt.id
}
resource "aws_route_table_association" "pub_assoc_2c" {
  subnet_id      = aws_subnet.web_pub_2c.id
  route_table_id = aws_route_table.pub_rt.id
}

resource "aws_route_table_association" "app_assoc" {
  subnet_id      = aws_subnet.app_pri.id
  route_table_id = aws_route_table.pri_rt.id
}
resource "aws_route_table_association" "app_assoc_2c" {
  subnet_id      = aws_subnet.app_pri_2c.id
  route_table_id = aws_route_table.pri_rt.id
}

resource "aws_route_table_association" "db_assoc" {
  subnet_id      = aws_subnet.db_pri.id
  route_table_id = aws_route_table.pri_rt.id
}
resource "aws_route_table_association" "db_assoc_2c" {
  subnet_id      = aws_subnet.db_pri_2c.id
  route_table_id = aws_route_table.pri_rt.id
}

# --- Security Groups ---
# 1. 외부 WEB ALB용 보안 그룹
resource "aws_security_group" "alb_sg" {
  name   = "LSO-WEB-ALB-SG"
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
}

# 2. WEB EC2 인스턴스용 보안 그룹
resource "aws_security_group" "web_sg" {
  name   = "LSO-WEB-EC2-SG"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # ALB를 통해서만 허용
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # SSH 접속 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. 내부 APP ALB용 보안 그룹 (추가)
resource "aws_security_group" "app_alb_sg" {
  name   = "LSO-APP-ALB-SG"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # WEB EC2에서 오는 트래픽만 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. APP EC2 인스턴스용 보안 그룹
resource "aws_security_group" "app_sg" {
  name   = "LSO-APP-EC2-SG"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port       = 5000
    to_port         = 5000
    protocol        = "tcp"
    security_groups = [aws_security_group.app_alb_sg.id] # 내부 ALB에서 오는 트래픽 허용
  }
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id] # WEB 서버를 통한 SSH 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 5. DB용 보안 그룹
resource "aws_security_group" "db_sg" {
  name   = "LSO-DB-SG"
  vpc_id = aws_vpc.lso_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id] # APP EC2에서 오는 트래픽만 허용
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}