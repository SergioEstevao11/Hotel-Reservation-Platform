variable "name" {}
variable "subnet_ids" {
  type = list(string)
}
variable "vpc_id" {}
variable "security_group_id" {}
