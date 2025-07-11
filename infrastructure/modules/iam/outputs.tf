output "execution_role_arn" {
  value = aws_iam_role.ecs_execution.arn
}

output "task_role_arn" {
  value = aws_iam_role.ecs_task.arn
}

output "dynamodb_access_policy_arn" {
  value = aws_iam_policy.dynamodb_access.arn
}

output "kms_dynamodb_access" {
  value = aws_iam_policy.kms_dynamodb_access.arn
}