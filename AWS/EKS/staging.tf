locals {
  staging = {
    staging = {
      region               = "us-east-2"
      availability_zones   = ["us-east-2a","us-east-2b"]
      name                 = "microfocus"
      vpc_cidr_block       = "10.3.0.0/16"
      subnet_block_size    = "4"

      idm-engine_ami_id             = "ami-054462c52d9c225ce"
      idm-engine_instance_type      = "t3.xlarge"
      idm-engine_key_name           = "idm-engine-pem"
      idm-engine_public_association = true
      idm-engine_storage            = 100
      idm-engine_monitoring         = false

      idm-applications_ami_id             = "ami-054462c52d9c225ce"
      idm-applications_instance_type      = "t3.xlarge"
      idm-applications_key_name           = "idm-applications-pem"
      idm-applications_public_association = true
      idm-applications_storage            = 100
      idm-applications_monitoring         = false

      access-manager_ami_id             = "ami-054462c52d9c225ce"
      access-manager_instance_type      = "t3.xlarge"
      access-manager_key_name           = "access_manager-pem"
      access-manager_public_association = true
      access-manager_storage            = 100
      access-manager_monitoring         = false

      dd_api_key = "6709ed8af8dfafab0821325c8bf4e957"
      dd_app_key = "5bf87fd1ca721cde094d361bd2fb33003bfe1fc8"
      dd_site    = "datadoghq.com"
    }
  }
}
