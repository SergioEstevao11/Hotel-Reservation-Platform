variable "task_family" {}
variable "image" {}
variable "cpu" { default = "256" }
variable "memory" { default = "512" }

variable "execution_role_arn" {}
variable "task_role_arn" {}
variable "cluster_arn" {}
variable "subnet_ids" {
  type = list(string)
}
variable "security_group_id" {}
variable "service_name" {}
variable "log_group_name" {}
variable "region" {}

variable "target_group_arn" {}