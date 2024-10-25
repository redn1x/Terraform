
resource "aws_security_group" "ccDBSecurityGroup" {
  name   = "cc-db-security-group"
  vpc_id = var.cc_vpc_id

  ingress {
    from_port = 5432
    to_port   = 5432
    protocol  = "tcp"
    cidr_blocks = [
      var.cc_private_subnet_cidrs[0],
      var.cc_private_subnet_cidrs[1]
    ]
  }
  tags = {
    Name    = "ccDBSecurityGroup"
    Project = "CC TF Demo"
  }
}

resource "aws_instance"  "ccRDS" {
  ami                         = local.ami_id
  instance_type               = local.instance_type
  subnet_id                   = var.cc_private_subnets[0].id
  vpc_security_group_ids      = [aws_security_group.ccDBSecurityGroup.id]
  associate_public_ip_address =  true
  source_dest_check           = false
  key_name                    =  local.key_name
 
 
  tags = {
    Name    = "ccRDS"
    Project = "CC TF Demo"
  }
}