resource "aws_sqs_queue" "main" {
  name = var.queue_name
  kms_master_key_id = "alias/aws/sqs"
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.queue_name}-dlq"
}

resource "aws_sqs_queue_policy" "sns_policy" {
  queue_url = aws_sqs_queue.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "Allow-SNS-SendMessage"
      Effect = "Allow"
      Principal = {
        Service = "sns.amazonaws.com"
      }
      Action   = "sqs:SendMessage"
      Resource = aws_sqs_queue.main.arn
      Condition = {
        ArnEquals = {
          "aws:SourceArn" = var.topic_arn
        }
      }
    }]
  })
}

resource "aws_sns_topic_subscription" "sns_to_sqs" {
  topic_arn = var.topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.main.arn

  raw_message_delivery = true
}
