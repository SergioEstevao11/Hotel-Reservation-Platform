variable "name" {
  description = "Logical name for the Lambda"
  type        = string
}

variable "queue_name" {
  description = "SQS queue name"
  type        = string
}

variable "queue_arn" {
  description = "SQS queue ARN"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to zipped Lambda code"
  type        = string
}

variable "handler" {
  description = "Handler function entry point"
  type        = string
}

variable "environment" {
  description = "Environment variables for Lambda"
  type        = map(string)
  default     = {}
}

variable "role_arn" {
  description = "IAM role ARN for the Lambda"
  type        = string
}
