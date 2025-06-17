resource "aws_lambda_function" "this" {
  function_name = "${var.name}-consumer"
  filename      = var.lambda_zip_path
  handler       = var.handler
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_exec.arn
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  environment {
    variables = merge(
      {
        QUEUE_NAME = var.queue_name
      },
      var.environment
    )
  }
}

resource "aws_lambda_event_source_mapping" "sqs" {
  event_source_arn = var.queue_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = 1
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "sqs_access" {
  name = "AllowQueueAccess"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes"
      ],
      Resource = var.queue_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "custom" {
  for_each   = var.policy_arns
  role       = aws_iam_role.lambda_exec.name
  policy_arn = each.value
}