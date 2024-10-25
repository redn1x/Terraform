variable "name" {
  description = "The name of the EC2 instance"
  type        = string
}

variable "environment" {
  description = "The environment of the EC2 resource (e.g. dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The VPC id where the EC2 resource should reside"
  type        = string
}

variable "ami_id" {
  description = "Image ID of the EC2 resource (e.g. ubuntu, amazon linux, etc)"
  type        = string
}

variable "instance_type" {
  description = "The type of the EC2 resource (e.g. t2.micro, t2.large, etc)"
  type        = string
}

variable "key_name" {
  description = "Key name of the EC2 resource used to ssh to the server"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the EC2 resource should reside"
  type        = string
}

variable "public_ip_address" {
  description = "If the EC2 resource should have a public address or not"
  type        = bool
}

variable "monitoring" {
  description = "If the EC2 resource should have monitoring"
  type        = bool
}

variable "storage" {
  description = "The size of storage space of the EC2 resource"
  type        = number
}

variable "policy_arns" {
  type    = "list"
  default = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
}