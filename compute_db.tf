<<<<<<< HEAD
# resource "aws_instance" "web_server" {
#   ami                    = "ami-0ecfdfd1c8ae01aec"
#   instance_type          = "t3.micro"
#   subnet_id              = aws_subnet.web_pub.id
#   key_name               = var.key_name
#   vpc_security_group_ids = [aws_security_group.web_sg.id]
#   associate_public_ip_address = true
#   depends_on = [aws_instance.app_server]

#   user_data = <<-EOF
# #!/bin/bash
# sudo dnf update -y
# sudo dnf -y install nginx
# sudo dnf -y install git
# sudo systemctl enable --now nginx

# cat << CONF | sudo tee /etc/nginx/conf.d/my_board.conf
# server {
#     listen 80;
#     server_name _;

#     # 이미지 업로드 용량 제한 해제 (10MB)
#     client_max_body_size 10M;

#     # 프론트엔드 정적 파일 위치
#     location / {
#         root /usr/share/nginx/html;
#         index index.html;
#         try_files \$uri \$uri/ /index.html;
#     }

#     # 백엔드 API 서버 연결 (Reverse Proxy)
#     location /api/ {
#         proxy_pass http://${aws_instance.app_server.private_ip}:5000;
#         proxy_set_header Host \$host;
#         proxy_set_header X-Real-IP \$remote_addr;
#         proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto \$scheme;

#         # Proxy 타임아웃 설정 (대용량 파일 업로드 대비)
#         proxy_connect_timeout 300s;
#         proxy_send_timeout 300s;
#         proxy_read_timeout 300s;
#     }
# }
# CONF

# sudo rm -f /etc/nginx/conf.d/default.conf
# sudo rm -rf /usr/share/nginx/html/*
# sudo git clone https://github.com/zipgaskkukdp/3tier.git /tmp/my_web_site
# sudo cp -r /tmp/my_web_site/* /usr/share/nginx/html/

# sudo systemctl restart nginx
# EOF



#   root_block_device {
#     volume_type = "gp3"
#     volume_size = 8
#     iops        = 3000
#   }

#   tags = { Name = "LSO-PUB-WEB-2A" }
# }


=======
>>>>>>> 373dabd4688e14622ea782970521a54f4d6ee3ed
# 1. Web 서버용 시작 템플릿 (Launch Template)
resource "aws_launch_template" "web_lt" {
  name_prefix   = "lso-web-lt-"
  image_id      = "ami-0ecfdfd1c8ae01aec"
  instance_type = "t3.micro"
  key_name      = var.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
#!/bin/bash
sudo dnf update -y
sudo dnf -y install nginx git
sudo systemctl enable --now nginx

cat << CONF | sudo tee /etc/nginx/conf.d/my_board.conf
server {
    listen 80;
    server_name _;

    client_max_body_size 10M;

    location / {
        root /usr/share/nginx/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://${aws_instance.app_server.private_ip}:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        proxy_connect_timeout 300s;
        proxy_send_timeout 300s;
        proxy_read_timeout 300s;
    }
}
CONF

sudo rm -f /etc/nginx/conf.d/default.conf
sudo rm -rf /usr/share/nginx/html/*
sudo git clone https://github.com/zipgaskkukdp/3tier.git /tmp/my_web_site
sudo cp -r /tmp/my_web_site/* /usr/share/nginx/html/

sudo systemctl restart nginx
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "LSO-PUB-WEB-ASG" }
  }
}

# 2. Application Load Balancer (ALB) 구성
resource "aws_lb" "web_alb" {
  name               = "lso-web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.web_pub.id, aws_subnet.web_pub_2c.id]
  tags               = { Name = "LSO-WEB-ALB" }
}

resource "aws_lb_target_group" "web_tg" {
  name     = "lso-web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.lso_vpc.id
}

<<<<<<< HEAD
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

=======
>>>>>>> 373dabd4688e14622ea782970521a54f4d6ee3ed
# 3. Auto Scaling Group (ASG) 구성
resource "aws_autoscaling_group" "web_asg" {
  name                = "lso-web-asg"
  vpc_zone_identifier = [aws_subnet.web_pub.id, aws_subnet.web_pub_2c.id]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  target_group_arns   = [aws_lb_target_group.web_tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }
}

# 4. CloudWatch 알람 및 오토스케일링 정책 (Scale Out & Scale In)
# 4-1. Scale Out (서버 늘리기)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "web-scale-out"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "web-high-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 70 # CPU 70% 이상일 때
  alarm_actions       = [aws_autoscaling_policy.scale_out.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}

# 4-2. Scale In (서버 줄이기)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "web-scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.web_asg.name
}

resource "aws_cloudwatch_metric_alarm" "low_cpu" {
  alarm_name          = "web-low-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 120
  statistic           = "Average"
  threshold           = 30 # CPU 30% 이하일 때
  alarm_actions       = [aws_autoscaling_policy.scale_in.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_asg.name
  }
}



resource "aws_instance" "app_server" {
  ami                    = "ami-0ecfdfd1c8ae01aec"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.app_pri.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  depends_on             = [aws_db_instance.rds, aws_s3_bucket.storage]

  user_data = <<-EOF
  #!/bin/bash
  sudo dnf -y update
  sudo dnf -y install python3-pip mariadb105 gcc python3-devel git
  pip3 install flask pymysql boto3 flask-cors python-dotenv gunicorn
  
<<<<<<< HEAD
=======

>>>>>>> 373dabd4688e14622ea782970521a54f4d6ee3ed
  mkdir -p /home/ec2-user/app
  sudo chown -R ec2-user:ec2-user /home/ec2-user/app
  cd /home/ec2-user/app
  sudo -u ec2-user git clone https://github.com/zipgaskkukdp/3tier-back.git .
  sudo -u ec2-user pip3 install flask pymysql boto3 flask-cors python-dotenv gunicorn

  cat << ENVEFF | sudo tee /home/ec2-user/app/.env
  DB_HOST=${aws_db_instance.rds.address}
  DB_USER=${var.db_username}
  DB_PASS=${var.db_password}
  SECRET_KEY=${var.flask_secret_key}
  S3_BUCKET=${aws_s3_bucket.storage.id}
  S3_KEY=${var.aws_access_key}
  S3_SECRET=${var.aws_secret_key}
  S3_REGION=ap-northeast-2
  ENVEFF

  cd /home/ec2-user/app
  sudo -u ec2-user nohup gunicorn --bind 0.0.0.0:5000 app:app > /home/ec2-user/app.log 2>&1 &

  EOF

  tags = { Name = "LSO-PRI-APP-2A" }
}

<<<<<<< HEAD
=======

>>>>>>> 373dabd4688e14622ea782970521a54f4d6ee3ed
resource "aws_db_subnet_group" "rds_sub" {
  name       = "lso-rds-sg"
  subnet_ids = [aws_subnet.db_pri.id, aws_subnet.dummy_pri.id]
}

resource "aws_db_instance" "rds" {
  identifier             = "lso-rds"
  engine                 = "mysql"
  engine_version         = "8.0"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  kms_key_id             = aws_kms_key.rds_key.arn
  storage_encrypted      = true
  db_subnet_group_name   = aws_db_subnet_group.rds_sub.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  username               = "root"
  password               = var.db_password
  skip_final_snapshot    = true
}

resource "aws_s3_bucket" "storage" {
  bucket        = "niha5ma-storage-904053119728-final"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "storage_pab" {
  bucket = aws_s3_bucket.storage.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_ownership_controls" "storage_oc" {
  bucket = aws_s3_bucket.storage.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "storage_acl" {
  depends_on = [
    aws_s3_bucket_public_access_block.storage_pab,
    aws_s3_bucket_ownership_controls.storage_oc,
  ]

  bucket = aws_s3_bucket.storage.id
  acl    = "public-read"
}

resource "aws_s3_bucket_policy" "storage_policy" {
  bucket = aws_s3_bucket.storage.id

  depends_on = [
    aws_s3_bucket_public_access_block.storage_pab
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowFullAccessToRoot"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action = "s3:*"
        Resource = [
          "${aws_s3_bucket.storage.arn}",
          "${aws_s3_bucket.storage.arn}/*"
        ]
      },
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.storage.arn}/*"
      }
    ]
  })
<<<<<<< HEAD
=======
}

# 1. 기존 ACM 인증서 불러오기 (ACM에 이미 있는 인증서 사용)
data "aws_acm_certificate" "existing_cert" {
  domain   = var.domain_name
  statuses = ["ISSUED"]
}

# 2. HTTPS 리스너 추가 (인증서 연결)
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.web_alb.arn # 본인의 ALB 리소스명 확인
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.existing_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn # 본인의 타겟그룹 리소스명 확인
  }
}

# 3. 기존 80포트 리스너 수정 (HTTP -> HTTPS 자동 리다이렉트)
# 만약 기존에 aws_lb_listener "web_listener"가 있다면 아래 내용으로 교체하세요.
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
>>>>>>> 373dabd4688e14622ea782970521a54f4d6ee3ed
}