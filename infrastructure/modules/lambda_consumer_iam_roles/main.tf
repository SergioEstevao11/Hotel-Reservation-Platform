resource "aws_iam_role" "this" {
  name = "${var.name}-lambda-role"

  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
}

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

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

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

resource "aws_iam_role_policy_attachment" "custom" {
  for_each   = { for i, arn in var.custom_policy_arns : i => arn }

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

data "aws_iam_policy_document" "lambda_logs" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region}:log-group:/aws/lambda/${var.name}-consumer:*"]
  }
}

resource "aws_iam_policy" "lambda_logs" {
  name   = "${var.name}-lambda-logs"
  policy = data.aws_iam_policy_document.lambda_logs.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_logs.arn
}