resource "aws_lambda_function" "this" {
  function_name    = "${var.name}-consumer"
  filename         = var.lambda_zip_path
  handler          = var.handler
  runtime          = "python3.11"
  role             = var.role_arn
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
