variable "region" {
  description = "AWS Region"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
}
