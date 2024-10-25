variable "name" {
  default = ""
}

variable "region" {}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
}

variable "subnet_block_size" {
  description = "The size of the CIDR block for each subnet (e.g. a value of 4 is equivalent to 16 IP addresses)"
}

variable "availability_zones" {
  description = "List of availability zone IDs (e.g. [\"a\", \"b\"])"
  type        = "list"
}

variable "log_retention_period" {
  default = 0
}

# variable "log_kms_key" {
#   default = ""
# }

variable "tags" {
  type    = "map"
  default = {}
}