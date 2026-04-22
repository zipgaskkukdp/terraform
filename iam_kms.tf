/*resource "aws_iam_user" "lso_user" {
  name = "LSO-USER"
}

resource "aws_iam_user_policy_attachment" "att_vpc" {
  user       = aws_iam_user.lso_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
}

resource "aws_iam_user_policy_attachment" "att_s3" {
  user       = aws_iam_user.lso_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_user_policy_attachment" "att_ec2" {
  user       = aws_iam_user.lso_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
}*/

resource "aws_kms_key" "rds_key" {
  description             = "RDS Encryption Key"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "key-default-1"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

data "aws_caller_identity" "current" {}
