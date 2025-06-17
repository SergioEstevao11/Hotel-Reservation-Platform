variable "name" {}
variable "queue_arn" {}
variable "queue_name" {}
variable "lambda_zip_path" {}
variable "handler" {}
variable "environment" {
  type        = map(string)
  description = "Environment variables for the Lambda function"
  default     = {}
}
variable "policy_arns" {
  type        = map(string)
  description = "List of IAM policy ARNs to attach to this Lambda"
  default     = {}
}