resource "aws_s3_bucket" "s3_bucket" {
  bucket = "mustafa-devopsv2-tfstate"

  tags = {
    Name = "My S3 bucket"
  }
}


resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.s3_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}


# Trusts GitHub Actions to authenticate to this AWS account without storing long-lived keys
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# The role GitHub Actions will assume, trust is restricted to only your specific repo
resource "aws_iam_role" "github_actions" {
  name = "github-actions-ecs2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          # Ensures only tokens meant for AWS STS are accepted
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          # Restricts which repo is allowed to assume this role
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:musti579/ecsv2:*"
          }
        }
      }
    ]
  })
}

# Permissions this role actually has once assumed: push to ECR, register task defs, trigger CodeDeploy
resource "aws_iam_role_policy" "github_actions" {
  name = "github-actions-ecs2-policy"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Lets the pipeline build and push Docker images to ECR
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken", "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer", "ecr:BatchGetImage", "ecr:PutImage",
          "ecr:InitiateLayerUpload", "ecr:UploadLayerPart", "ecr:CompleteLayerUpload"
        ]
        Resource = "*"
      },
      {
        # Lets the pipeline register a new task definition revision after building a new image
        Effect   = "Allow"
        Action   = ["ecs:RegisterTaskDefinition", "ecs:DescribeTaskDefinition"]
        Resource = "*"
      },
      {
        # Lets the pipeline trigger a blue-green deployment via CodeDeploy
        Effect = "Allow"
        Action = [
          "codedeploy:CreateDeployment", "codedeploy:GetDeployment",
          "codedeploy:GetDeploymentGroup", "codedeploy:GetApplication",
          "codedeploy:RegisterApplicationRevision"
        ]
        Resource = "*"
      },
      {
        # Required so ECS can assume the task/execution roles referenced in the new task definition
        Effect   = "Allow"
        Action   = "iam:PassRole"
        Resource = "*"
      }
    ]
  })
}

# Exposes the role's ARN so it can be added as a GitHub repo secret (AWS_ROLE_ARN)
output "role_arn" {
  value = aws_iam_role.github_actions.arn
}