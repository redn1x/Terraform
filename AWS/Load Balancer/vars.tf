#####################################
## Network -    Variables ##
#####################################


variable "aws_region" {
  type = string
  description = "AWS region"
  default = "eu-west-2"
}

variable "app_environment" {
  type        = string
  description = "Environment"
  default = "sandbox"
}
variable "customer_name" {
  type        = string
  description = "customer name"
  default = "Oksy-tech"
}


variable "app_name_app" {
  type        = string
  description = "Application name"
  default = "Oksy.COM"
}

variable "app_oksy_app" {
  type        = string
  description = "Application name"
  default = "Oksy.COM"
}


variable "app_name_db" {
  type        = string
  description = "Application name"
  default = "DB01.CONNECTEDMFG.COM"
}

variable "app_name_lic" {
  type        = string
  description = "Application name"
  default = "LC01.CONNECTEDMFG.COM"
}


variable "aws_az" {
  type        = list 
  description = "AWS AZ"
  default     = [ "eu-west-2a","eu-west-2b"]
}


variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.220.100.64/27"
}


variable "public_subnet_cidr-1" {
  type        = string
  description = "CIDR for the public subnet"
  default     = "10.220.100.64/28"
}

variable "public_subnet_cidr-2" {
  type        = string
  description = "CIDR for the private subnet"
  default     = "10.220.100.80/28"
}

variable "vpc_name" {
  type        = string
  description = "vpc name"
  default = "VPC01"
}


variable "ec2_tag" {
  type        = string
  description = "Environment"
  default = "oksy"
}


########################################
## EC2- Variables ##
########################################

variable "windows_instance_type" {
  type        = list
  description = "EC2 instance type for Windows Server"
  default     = ["t3.xlarge","t3.large","t3.medium"]
}


variable "windows_associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address to the EC2 instance"
  default     = false
}

variable "windows_data_volume_size_app"{
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"

}


variable "windows_root_volume_size_app" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}



variable "windows_root_volume_size_db" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}

variable "windows_data_volume_size_db" {
  type        = number
  description = "Volumen size of data volumen of Windows Server"
  default     = "500"
}

variable "windows_root_volume_size_lic" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}

variable "windows_data_volume_size_lic" {
  type        = number
  description = "Volumen size of data volumen of Windows Server"
  default     = "100"
}

variable "windows_root_volume_type" {
  type        = string
  description = "Volumen type of root volumen of Windows Server. Can be standard, gp3, gp2, io1, sc1 or st1"
  default     = "gp2"
}

variable "windows_data_volume_type" {
  type        = string
  description = "Volumen type of data volumen of Windows Server. Can be standard, gp3, gp2, io1, sc1 or st1"
  default     = "gp2"
}

