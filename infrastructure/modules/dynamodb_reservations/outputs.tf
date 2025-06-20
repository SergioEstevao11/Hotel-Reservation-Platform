output "table_name" {
  value = aws_dynamodb_table.this.name
}
output "table_arn" {
  value = aws_dynamodb_table.this.arn
}

output "table_kms_key_arn" {
  value = aws_kms_key.dynamodb_key.arn
}