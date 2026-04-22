# 1. Route 53 호스팅 영역(Hosted Zone) 생성
resource "aws_route53_zone" "main" {
  name = var.domain_name
  tags = { Name = "LSO-ROUTE53-ZONE" }
}

# 2. 로드밸런서(ALB)와 도메인을 연결하는 Alias 레코드 (예: 루트 도메인 연결)
resource "aws_route53_record" "root_domain" {
  zone_id = aws_route53_zone.main.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.web_alb.dns_name
    zone_id                = aws_lb.web_alb.zone_id
    evaluate_target_health = true
  }
}

# # (선택) www 서브도메인 레코드 추가
# resource "aws_route53_record" "www" {
#   zone_id = aws_route53_zone.main.zone_id
#   name    = "www.${var.domain_name}"
#   type    = "A"

#   alias {
#     name                   = aws_lb.web_alb.dns_name
#     zone_id                = aws_lb.web_alb.zone_id
#     evaluate_target_health = true
#   }
# }

# 3. 가비아에 등록할 네임서버 주소를 터미널에 출력
output "route53_name_servers" {
  description = "가비아 홈페이지에 등록해야 할 네임서버 주소 4개입니다."
  value       = aws_route53_zone.main.name_servers
<<<<<<< HEAD
}
=======
}
>>>>>>> 373dabd4688e14622ea782970521a54f4d6ee3ed
