resource "aws_iam_openid_connect_provider" "this" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = ["ffffffffffffffffffffffffffffffffffffffff"]
}

resource "aws_ecr_repository" "main" {
  name = var.ecr_name
}

resource "aws_iam_role" "github-action-repo-access" {
  name = "github-ecr-access"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.this.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike  = {
            "token.actions.githubusercontent.com:sub": "repo:${var.organization}/${var.ecr_name}:*"
          }
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "github-action-repo-access" {
  statement {
    effect = "Allow"

    actions = [
      "ecr:GetAuthorizationToken"
    ]

    resources = ["*"]
  }
  statement {
    effect = "Allow"

    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart"
    ]

    resources = [aws_ecr_repository.main.arn]
  }
}

resource "aws_iam_policy" "github-action-repo-access" {
  policy = data.aws_iam_policy_document.github-action-repo-access.json
}

resource "aws_iam_role_policy_attachment" "github-action-repo-access" {
  role       = aws_iam_role.github-action-repo-access.name
  policy_arn = aws_iam_policy.github-action-repo-access.arn
}