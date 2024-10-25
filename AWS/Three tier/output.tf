output "instance_details" {
  value = {
    MES_APP_SERVERS = [aws_instance.windows-server-app1.*.id]
    MES_DB1_SERVERS = [aws_instance.windows-server-db1.*.id]
    MES_DB2_SERVERS = [aws_instance.windows-server-db2.*.id]
    #MES_LIC_SERVERS = [aws_instance.windows-server-lic.*.id]
    # MES_AD_SERVERS = [aws_instance.windows-server-ad.*.id]
    # MES_MON_SERVERS = [aws_instance.windows-server-mon.*.id]
    # MES_VPN_SERVERS = [aws_instance.windows-server-vpn.*.id]
    # MES_instance_eips = [aws_eip.windows-eip.*.public_ip]
    MES_instance_name_app_servers = [aws_instance.windows-server-app1.*.tags.Name]
    MES_instance_name_db1_servers =  [aws_instance.windows-server-db1.*.tags.Name]
    MES_instance_name_db2_servers =  [aws_instance.windows-server-db2.*.tags.Name]
    #MES_instance_name_lic_servers =  [aws_instance.windows-server-lic.*.tags.Name]
    #MES_vpc_cidr_block = aws_vpc.vpc.cidr_block
    #MES_public_subnets = [aws_subnet.public-subnet-1.id, aws_subnet.public-subnet-2.id]
   
  }

  }
