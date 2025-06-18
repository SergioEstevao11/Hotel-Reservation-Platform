variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "AZs for the subnets"
  type        = list(string)
}

variable "region" {}