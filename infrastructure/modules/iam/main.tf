
###########################
# IAM Roles
###########################

data "aws_iam_policy_document" "ecs_execution_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_assume_role.json
}

data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task" {
  name               = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

###########################
# Attach AWS Managed Policy
###########################

resource "aws_iam_role_policy_attachment" "execution_logs_policy" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

###########################
# S3 Read-Only Access to All Buckets for ECS Execution Role
###########################

data "aws_iam_policy_document" "s3_read_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::*",
      "arn:aws:s3:::*/*"
    ]
    effect = "Allow"
  }
}

resource "aws_iam_policy" "s3_read_access" {
  name   = "ecs-execution-s3-read"
  policy = data.aws_iam_policy_document.s3_read_access.json
}

resource "aws_iam_role_policy_attachment" "execution_attach_s3_read" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.s3_read_access.arn
}

###########################
# SNS Publish Policy
###########################

data "aws_iam_policy_document" "sns_publish" {
  statement {
    actions   = ["sns:Publish"]
    resources = [var.sns_topic_arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "sns_publish" {
  name   = "sns-publish-policy"
  policy = data.aws_iam_policy_document.sns_publish.json
}

resource "aws_iam_role_policy_attachment" "task_attach_sns_publish" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.sns_publish.arn
}

###########################
# DynamoDB Access Policy
###########################

data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]
    resources = [var.dynamodb_reservations_arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name   = "dynamodb-access"
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_dynamodb" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

data "aws_iam_policy_document" "kms_dynamodb_access" {
  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [var.table_kms_key_arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "kms_dynamodb_access" {
  name   = "kms-dynamodb-access"
  policy = data.aws_iam_policy_document.kms_dynamodb_access.json
}

resource "aws_iam_role_policy_attachment" "ecs_kms_access" {
  role       = aws_iam_role.ecs_task.name
  policy_arn = aws_iam_policy.kms_dynamodb_access.arn
}

