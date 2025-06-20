variable "name" {
  description = "Lambda role name prefix"
  type        = string
}

variable "queue_arn" {
  description = "SQS queue ARN"
  type        = string
  default     = null
}

variable "custom_policy_arns" {
  description = "Additional policy ARNs"
  type        = list(string)
  default     = []
}

variable "region" {}