variable "region" {
  description = "AWS Region"
  type        = string
  default     = "eu-west-1"
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["eu-west-1a", "eu-west-1b"]
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
}
