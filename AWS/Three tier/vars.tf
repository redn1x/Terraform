#####################################
## Network -    Variables ##
#####################################


variable "aws_region" {
  type = string
  description = "AWS region"
  default = "us-east-1"
}

variable "app_environment" {
  type        = string
  description = "Environment"
  default = "Prod"
}

variable "app_stg_app" {
  type        = string
  description = "Application name"
  default = "CONNECTEDMFG.COM"
}

variable "app_name_app" {
  type        = string
  description = "Application name"
  default = "AUE1SWPSA01"
}

variable "app_name_db1" {
  type        = string
  description = "Application name"
  default = "AUE1SWPDB01"
}

variable "app_name_db2" {
  type        = string
  description = "Application name"
  default = "AUE1SWPDB02"
}

variable "lic_name" {
  type        = string
  description = "Application name"
  default = "AUE1SWPLC01"
}

variable "aws_az" {
  type        = list 
  description = "AWS AZ"
  default     = [ "us-east-1a","us-east-1c"]
}


variable "vpc_cidr" {
  type        = string
  description = "CIDR for the VPC"
  default     = "10.220.200.64/27"
}


variable "public_subnet_cidr-1" {
  type        = string
  description = "CIDR for the public subnet"
  default     = "10.220.200.64/28"
}

variable "public_subnet_cidr-2" {
  type        = string
  description = "CIDR for the public subnet"
  default     = "10.220.200.80/28"
}


variable "vpc_name" {
  type        = string
  description = "vpc name"
  default = "AUE1SWPVPC01"
}

variable "customer_name" {
  type        = string
  description = "Customer name"
  default = "Healthineers-Walpole"
}


########################################
## EC2- Variables ##
########################################

variable "windows_instance_type" {
  type        = list
  description = "EC2 instance type for Windows Server"
  default     = ["t3.xlarge","t3.medium"]
}


variable "windows_associate_public_ip_address" {
  type        = bool
  description = "Associate a public IP address to the EC2 instance"
  default     = false
}

variable "windows_root_volume_size_app" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}

variable "windows_root_volume_size_app_c" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "125"
}

variable "windows_data_volume_size_app_d" {
  type        = number
  description = "Volumen size of data volumen of Windows Server"
  default     = "125"
}

variable "windows_data_volume_size_app_f" {
  type        = number
  description = "Volumen size of data volumen of Windows Server"
  default     = "500"
}

variable "windows_root_volume_size_db" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}

variable "windows_data_volume_size_db" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
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
  description = "Volumen type of root volumen of Windows Server. Can be standard, gp3, gp3, io1, sc1 or st1"
  default     = "gp3"
}

variable "windows_data_volume_type" {
  type        = string
  description = "Volumen type of data volumen of Windows Server. Can be standard, gp3, gp3, io1, sc1 or st1"
  default     = "gp3"
}

variable "windows_root_volume_size_dbc" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "125"
}

variable "windows_root_volume_size_dbd" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "125"
}

variable "windows_root_volume_size_dbe" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}

variable "windows_root_volume_size_dbf" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "100"
}

variable "windows_root_volume_size_dbg" {
  type        = number
  description = "Volumen size of root volumen of Windows Server"
  default     = "150"
}


variable "ec2_tag" {
  type        = string
  description = "Environment"
  default = "migO0SDOZVJMB"
}
