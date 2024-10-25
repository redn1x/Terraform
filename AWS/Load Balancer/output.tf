output "instance_details" {
  value = {
    MES_APP_SERVERS = [aws_instance.windows-server-app1.*.id,aws_instance.windows-server-app2.*.id]
    # MES_instance_eips = [aws_eip.windows-eip.*.public_ip]
    MES_instance_servers = [aws_instance.windows-server-app1.*.tags.Name,aws_instance.windows-server-app2.*.tags.Name,aws_instance.windows-server-db1.*.tags.Name,aws_instance.windows-server-db2.*.tags.Name,aws_instance.windows-server-int.*.tags.Name]
    MES_vpc_cidr_block = aws_vpc.vpc.cidr_block
    MES_public_subnets = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
   
  }

  }

