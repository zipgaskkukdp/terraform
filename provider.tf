# provider.tf
provider "aws" {
  region = var.region
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 버전 제약을 아예 풀어서 현재 설치된 6.38.0을 쓰도록 합니다.
    }
  }
}
