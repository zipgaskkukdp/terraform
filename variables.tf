variable "region" {
  default = "ap-northeast-2"
}

variable "key_name" {
  description = "EC2 접속을 위한 키페어 이름"
}

variable "db_username" {
  default = "root"
}

variable "db_password" {
  description = "RDS 데이터베이스 비밀번호"
}

variable "account_id" {
  description = "AWS 계정 ID"
}

variable "flask_secret_key" {
  description = "Flask 세션 암호화 키"
}

variable "aws_access_key" {
  description = "S3 접근을 위한 IAM 액세스 키"
}

variable "aws_secret_key" {
  description = "S3 접근을 위한 IAM 시크릿 키"
}

variable "domain_name" {
  description = "가비아에서 구매한 도메인 이름"
  type        = string
}
