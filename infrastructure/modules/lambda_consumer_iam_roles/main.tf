# IAM role for Lambda
resource "aws_iam_role" "this" {
  name = "${var.name}-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

# Assume role policy document
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    effect = "Allow"
  }
}

# Attach AWS managed Lambda execution policy
resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Optional inline policy for SQS access
data "aws_iam_policy_document" "sqs_access" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes"
    ]

    resources = [var.queue_arn]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy" "sqs_access" {
  name   = "AllowQueueAccess"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.sqs_access.json
}

# Attach custom managed policies
resource "aws_iam_role_policy_attachment" "custom" {
  for_each   = { for i, arn in var.custom_policy_arns : i => arn }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
