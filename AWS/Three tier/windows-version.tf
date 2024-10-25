################################################
# Get latest Windows Server AMI with Terraform #
################################################


# # Get latest Windows Server 2019 AMI
# data "aws_ami" "windows-2019" {
#   most_recent = true
#   owners      = ["amazon"]
#   filter {
#     name   = "name"
#     values = ["Windows_Server-2019-English-Full-Base-2023.07.12"]
#   }
#    filter {
#        name   = "virtualization-type"
#        values = ["hvm"]
#   }
     

#}
# # Get latest Windows Server 2019 with MSSQL 2019 Standard
# data "aws_ami" "windows-2019-mssql-2019" {
#   most_recent = true
#   owners      = ["801119661308"]
#   filter {
#     name   = "name"
#     values = ["Windows_Server-2019-English-Full-SQL_2019_Standard-2023.03.15"]
#   }
#   filter {
#        name   = "virtualization-type"
#        values = ["hvm"]
#   }
   
# }