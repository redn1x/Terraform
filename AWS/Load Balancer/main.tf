#####################################
##        NETWORK                  ##
#####################################


# Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
    Environment = var.app_environment
    map = var.ec2_tag
  }
}

# Define the public subnet-1
resource "aws_subnet" "public-subnet-1" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr-1
  availability_zone = var.aws_az[0]
  tags = {
    Name = "${lower(var.vpc_name)}-${lower(var.app_environment)}-public-subnet-1"
    Environment = var.app_environment
     map = var.ec2_tag
  }
}

# Define the public subnet-2
resource "aws_subnet" "public-subnet-2" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnet_cidr-2
  availability_zone = var.aws_az[1]
  tags = {
    Name = "${lower(var.vpc_name)}-${lower(var.app_environment)}-public-subnet-2"
    Environment = var.app_environment
    map  = var.ec2_tag
  }
}


# Define the internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${lower(var.vpc_name)}-${lower(var.app_environment)}-igw"
    Environment = var.app_environment
    map = var.ec2_tag
  }
}

# Define the public route table
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "${lower(var.vpc_name)}-${lower(var.app_environment)}-public-subnet-rt"
    Environment = var.app_environment
    map = var.ec2_tag
  }
}

#Assign the public route table to the public subnet
resource "aws_route_table_association" "public-rt-association-1" {
  subnet_id      = aws_subnet.public-subnet-1.id
  route_table_id = aws_route_table.public-rt.id
}

resource "aws_route_table_association" "public-rt-association-2" {
  subnet_id      = aws_subnet.public-subnet-2.id
  route_table_id = aws_route_table.public-rt.id
 
}

###################################
##              EC2              ##
###################################

#Bootstrapping PowerShell Script
data "template_file" "windows-userdata" {
  template = <<EOF
<powershell>
## Rename Machine
## Rename-Computer -NewName "$#{var.windows_instance_name}" -Force;
Set-LocalUser -Name "Administrator" -PasswordNeverExpires $true;
Initialize-Disk -Number 1;
New-Partition -DiskNumber 1 -UseMaximumSize -AssignDriveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel "Data";

#### Modules listed in the Install Guide
#Install-WindowsFeature -Name Web-Server -IncludeManagementTools;
Install-WindowsFeature -Name Web-WebServer;
Install-WindowsFeature -Name Web-Common-Http;
Install-WindowsFeature -Name Web-Default-Doc;
Install-WindowsFeature -Name Web-Dir-Browsing;
Install-WindowsFeature -Name Web-Http-Errors;
Install-WindowsFeature -Name Web-Static-Content;
Install-WindowsFeature -Name Web-Http-Redirect;
Install-WindowsFeature -Name Web-Health;
Install-WindowsFeature -Name Web-Http-Logging;
Install-WindowsFeature -Name Web-Custom-Logging;
Install-WindowsFeature -Name Web-Log-Libraries;
Install-WindowsFeature -Name Web-ODBC-Logging;
Install-WindowsFeature -Name Web-Request-Monitor;
Install-WindowsFeature -Name Web-Http-Tracing;
Install-WindowsFeature -Name Web-Performance;
Install-WindowsFeature -Name Web-Stat-Compression;
Install-WindowsFeature -Name Web-Dyn-Compression;
Install-WindowsFeature -Name Web-Security;
Install-WindowsFeature -Name Web-Filtering;
Install-WindowsFeature -Name Web-Digest-Auth;
Install-WindowsFeature -Name Web-Url-Auth;
Install-WindowsFeature -Name Web-Windows-Auth;
Install-WindowsFeature -Name Web-AppInit;
Install-WindowsFeature -Name Web-Net-Ext45;
Install-WindowsFeature -Name Web-Asp-Net45;
Install-WindowsFeature -Name Web-ISAPI-Ext;
Install-WindowsFeature -Name Web-ISAPI-Filter;
Install-WindowsFeature -Name Web-Includes;
Install-WindowsFeature -Name Web-Mgmt-Tools;
Install-WindowsFeature -Name Web-Mgmt-Console;
Install-WindowsFeature -Name Web-Mgmt-Compat;
Install-WindowsFeature -Name Web-Metabase;
Install-WindowsFeature -Name Web-Lgcy-Mgmt-Console;
Install-WindowsFeature -Name Web-Scripting-Tools;
Install-WindowsFeature -Name Net-Framework-45-ASPNET;
Install-WindowsFeature -Name NET-WCF-HTTP-Activation45;
Install-WindowsFeature -Name WAS;
Install-WindowsFeature -Name WAS-Process-Model;
Install-WindowsFeature -Name WAS-Config-APIs;
#### Additional Common Modules
Install-WindowsFeature -Name Web-Basic-Auth;
Install-WindowsFeature -Name Web-Windows-Auth;
Install-WindowsFeature -Name Telnet-Client;


#### Firewall rules
Enable-NetFirewallRule -DisplayName "World Wide Web Services (HTTP Traffic-In);
Enable-NetFirewallRule -DisplayName "World Wide Web Services (HTTPS Traffic-In);
New-NetFirewallRule -DisplayName "oksy Auth to Active Directory" -Direction Inbound -Action Allow -Protocol UDP -LocalPort 88;
New-NetFirewallRule -DisplayName "oksy LDAP Auth" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 389;
New-NetFirewallRule -DisplayName "oksy LDAP Auth-SSL" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 636;
New-NetFirewallRule -DisplayName "oksy   Studio" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 2882;
New-NetFirewallRule -DisplayName "Microsoft Exchange Notification" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 2883;
New-NetFirewallRule -DisplayName "MS SQL Server 2019" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 1433;
####### For License Server
New-NetFirewallRule -DisplayName "oksy License Server - Flexera - lmgrd.exe" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 28000;
New-NetFirewallRule -DisplayName "oksy License Server - Licensing Component - ugslmd.exe" -Direction Inbound -Action Allow -Protocol tcp -LocalPort 29000;

# Restart machine
shutdown -r -t 10;
</powershell>
EOF
}

#####################
## Key Pair - Main ##
#####################

# Generates a secure private key and encodes it as PEM
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Create the Key Pair
resource "aws_key_pair" "key_pair" {
  key_name   = "${lower(var.vpc_name)}-${lower(var.app_environment)}-windows-${lower(var.aws_region)}"  
  public_key = tls_private_key.key_pair.public_key_openssh
}

# Save file
resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}

# data "aws_iam_role" "example" {
#   name = "AmazonSSMRoleForInstancesQuickSetup"
# }

# Create EC2 Instance
resource "aws_instance" "windows-server-app1" {
  ami                         = "ami-0d67743feaea944bf"
  instance_type               = var.windows_instance_type[0]
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.aws-windows-sg.id]
  associate_public_ip_address = var.windows_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  #iam_instance_profile        =  data.aws_iam_role.example.name
  user_data                   = data.template_file.windows-userdata.rendered
  
  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size_app
    volume_type           = var.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.windows_data_volume_size_app
    volume_type           = var.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name        = "AP01.${var.app_name_app}"
    Environment = var.app_environment
    map = var.ec2_tag
    Customer     = var.customer_name
  }
}

resource "aws_instance" "windows-server-app2" {
  ami                         = "ami-0d67743feaea944bf"
  instance_type               = var.windows_instance_type[0]
  subnet_id                   = aws_subnet.public-subnet-2.id
  vpc_security_group_ids      = [aws_security_group.aws-windows-sg.id]
  associate_public_ip_address = var.windows_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  #iam_instance_profile        =  data.aws_iam_role.example.name
  user_data                   = data.template_file.windows-userdata.rendered
  
  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size_app
    volume_type           = var.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.windows_data_volume_size_app
    volume_type           = var.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name        = "AP02.${var.app_name_app}"
    Environment = var.app_environment
    Customer     = var.customer_name
    v = var.ec2_tag
  }
}

resource "aws_instance" "windows-server-db1" {
  ami                         = "ami-072d0afebb77ad51f"
  instance_type               = var.windows_instance_type[0]
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.aws-windows-sg.id]
  associate_public_ip_address = var.windows_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  #iam_instance_profile        =  data.aws_iam_role.example.name
  user_data                   = data.template_file.windows-userdata.rendered
  
  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size_app
    volume_type           = var.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.windows_data_volume_size_db
    volume_type           = var.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name        = "AEW2SHTDB01.${var.app_name_app}"
    Environment = var.app_environment
    map-migrated = var.ec2_tag
    Customer     = var.customer_name
  }
}

resource  "aws_instance" "windows-server-db2"{
  ami                         = "ami-072d0afebb77ad51f"
  instance_type               = var.windows_instance_type[0]
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.aws-windows-sg.id]
  associate_public_ip_address = var.windows_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  #iam_instance_profile        =  data.aws_iam_role.example.name
  user_data                   = data.template_file.windows-userdata.rendered
  
  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size_app
    volume_type           = var.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.windows_data_volume_size_app
    volume_type           = var.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name        = TDB02.${var.app_name_app}"
    Environment = var.app_environment
     map = var.ec2_tag
    Customer     = var.customer_name
  }
}

resource "aws_instance" "windows-server-int" {
  ami                         = "ami-0d67743feaea944bf"
  instance_type               = var.windows_instance_type[1]
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.aws-windows-sg.id]
  associate_public_ip_address = var.windows_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  #iam_instance_profile        =  data.aws_iam_role.example.name
  user_data                   = data.template_file.windows-userdata.rendered
  
  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size_app
    volume_type           = var.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.windows_data_volume_size_app
    volume_type           = var.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }
  
  tags = {
    Name        = "IN01.${var.app_name_app}"
    Environment = var.app_environment
    Customer     = var.customer_name
   map= var.ec2_tag
  }
}



# Define the security group for the Windows server
resource "aws_security_group" "aws-windows-sg" {
  name        = "${lower(var.vpc_name)}-${var.app_environment}-windows-sg"
  description = "Allow incoming connections"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["136.158.10.61/32"]
    description = "Allow incoming HTTP connections"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.220.100.0/27"]
    description = "Allow incoming RDP connections"
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.220.100.64/27"]
    description = "Allow incoming RDP connections"
  }
  

ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["10.220.100.32/27"]
    description = "Allow incoming RDP connections"
  }

ingress {
    from_port   = 0
    to_port     = 0
    protocol    =  "-1"
    cidr_blocks = ["10.220.100.32/27"]
    description = "Allow incoming license communications"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups =  [ aws_security_group.alb_sg.id ]
    description = "Allow incoming RDP connections"
  }
 ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    security_groups = [ aws_security_group.alb_sg.id ]
    description = "Allow incoming RDP connections"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${lower(var.vpc_name)}-${var.app_environment}-windows-sg"
    Environment = var.app_environment
  }
}

# Create EC2 Instance - LIC Server

resource "aws_instance" "windows-server-lic" {
  ami                         = "ami-0d67743feaea944bf"
  instance_type               = var.windows_instance_type[2]
  subnet_id                   = aws_subnet.public-subnet-1.id
  vpc_security_group_ids      = [aws_security_group.aws-windows-sg.id]
  #associate_public_ip_address = var.windows_associate_public_ip_address
  source_dest_check           = false
  key_name                    = aws_key_pair.key_pair.key_name
  #iam_instance_profile        =  data.aws_iam_role.example.name
  user_data                   = data.template_file.windows-userdata.rendered
  
  # root disk
  root_block_device {
    volume_size           = var.windows_root_volume_size_app
    volume_type           = var.windows_root_volume_type
    delete_on_termination = true
    encrypted             = true
  }

  # extra disk
  ebs_block_device {
    device_name           = "/dev/sdf"
    volume_size           = var.windows_data_volume_size_app
    volume_type           = var.windows_data_volume_type
    encrypted             = true
    delete_on_termination = true
  }

  
  tags = {
    Name        = "LC01.${var.app_name_app}"
    Environment = var.app_environment
    Customer     = var.customer_name
     map = var.ec2_tag
  }
}



resource "aws_eip" "windows-eip-app" {
  count = 5
  vpc = true

  tags = {
      Name        = "${lower(var.vpc_name)}-${var.app_environment}-windows-eip-app"
      Environment = var.app_environment
  }
}

resource "aws_eip_association" "app1" {
  instance_id = aws_instance.windows-server-app1.id
  allocation_id = aws_eip.windows-eip-app[0].id
}

resource "aws_eip_association" "app2" {
  instance_id = aws_instance.windows-server-app2.id
  allocation_id = aws_eip.windows-eip-app[1].id
}


resource "aws_eip_association" "db1" {
  instance_id = aws_instance.windows-server-db1.id
  allocation_id = aws_eip.windows-eip-app[2].id
}


resource "aws_eip_association" "db2" {
  instance_id = aws_instance.windows-server-db2.id
  allocation_id = aws_eip.windows-eip-app[3].id
}

resource "aws_eip_association" "int" {
  instance_id = aws_instance.windows-server-int.id
  allocation_id = aws_eip.windows-eip-app[4].id
}


#Create Application Load Balancer and Target Group
resource "aws_lb" "alb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  subnets            = [ aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id ]

  security_groups = [
    aws_security_group.alb_sg.id,
  ]

  tags = {
    Name = "1ALB"
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["112.204.171.80/32"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["112.204.171.80/32"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALBSG"
  }
}

resource "aws_lb_target_group" "tg" {
  name_prefix      = "alb-"
  port             = 80
  protocol         = "HTTP"
  vpc_id           = aws_vpc.vpc.id
  target_type      = "instance"
}

resource "aws_lb_target_group_attachment" "tgattach" {
  count = 4

  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = element(concat(aws_instance.windows-server-app1.*.id,aws_instance.windows-server-app2.*.id), count.index)
  port             = 80
}

# Create a listener for port 80
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}
