
terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket               = "microfocus-tfstate"
    key                  = "idm.tfstate"
    region               = "us-east-2"
    workspace_key_prefix = "idm"
    encrypt              = true
  }
}

locals {
  workspaces = "${merge(local.staging)}"
  workspace  = "${local.workspaces[terraform.workspace]}"
}

provider "aws" {
  region = local.workspace["region"]
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# CONFIGURE OUR KUBERNETES CONNECTIONS
# Note that we can't configure our Kubernetes connection until EKS is up and running, so we try to depend on the
# resource being created.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# The provider needs to depend on the cluster being setup.
provider "kubernetes" {
  version = "= 1.11.1"

  load_config_file       = false
  host                   = data.template_file.kubernetes_cluster_endpoint.rendered
  cluster_ca_certificate = base64decode(data.template_file.kubernetes_cluster_ca.rendered)
  token                  = data.aws_eks_cluster_auth.kubernetes_token.token
}

module "idm_vpc" {
  source = "./modules/networking"

  name = "coe-idm-portal-dev"

  region             = local.workspace["region"]
  vpc_cidr_block     = "${local.workspace["vpc_cidr_block"]}"
  subnet_block_size  = "${local.workspace["subnet_block_size"]}"
  availability_zones = "${local.workspace["availability_zones"]}"

  tags = {
    Name  = "idm_vpc"
    Environment  = "${terraform.workspace}"
  }
}

module "idm_engine" {
  source = "./modules/ec2_instance"

  name        = "idm-engine"
  environment = "${terraform.workspace}"

  vpc_id            = "${module.idm_vpc.vpc_id}"

  ami_id            = "${local.workspace["idm-engine_ami_id"]}"
  instance_type     = "${local.workspace["idm-engine_instance_type"]}"
  key_name          = "${local.workspace["idm-engine_key_name"]}"
  subnet_id         = "${module.idm_vpc.public_subnet_ids[0]}"
  public_ip_address = "${local.workspace["idm-engine_public_association"]}"
  monitoring        = "${local.workspace["idm-engine_monitoring"]}"
  storage           = "${local.workspace["idm-engine_storage"]}"
}

# idm-engine security group rules

resource "aws_security_group_rule" "idm_engine_ssh_rule" {
  security_group_id = module.idm_engine.security_group_id

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idm_engine_ndap_rule" {
  security_group_id = module.idm_engine.security_group_id

  type                     = "ingress"
  from_port                = 524
  to_port                  = 524
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idm_engine_ldaps_rule" {
  security_group_id = module.idm_engine.security_group_id

  type                     = "ingress"
  from_port                = 636
  to_port                  = 636
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idm_engine_imanager_rule" {
  security_group_id = module.idm_engine.security_group_id

  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idm_engine_imonitor_rule" {
  security_group_id = module.idm_engine.security_group_id

  type                     = "ingress"
  from_port                = 8030
  to_port                  = 8030
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

module "idm_applications" {
  source = "./modules/ec2_instance"

  name        = "idm-applications"
  environment = "${terraform.workspace}"

  vpc_id = "${module.idm_vpc.vpc_id}"

  ami_id            = "${local.workspace["idm-applications_ami_id"]}"
  instance_type     = "${local.workspace["idm-applications_instance_type"]}"
  key_name          = "${local.workspace["idm-applications_key_name"]}"
  subnet_id         = "${module.idm_vpc.public_subnet_ids[0]}"
  public_ip_address = "${local.workspace["idm-applications_public_association"]}"
  monitoring        = "${local.workspace["idm-applications_monitoring"]}"
  storage           = "${local.workspace["idm-applications_storage"]}"
}

# idm-applications security group rules

resource "aws_security_group_rule" "idm_applications_ssh_rule" {
  security_group_id = module.idm_applications.security_group_id

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idm_applications_tomcat_rule" {
  security_group_id = module.idm_applications.security_group_id

  type                     = "ingress"
  from_port                = 8443
  to_port                  = 8443
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "idm_applications_nginx_rule" {
  security_group_id = module.idm_applications.security_group_id

  type                     = "ingress"
  from_port                = 8600
  to_port                  = 8600
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

# resource "aws_security_group_rule" "idm_applications_postgresql_rule" {
#   security_group_id = module.idm_applications.security_group_id

#   type                     = "ingress"
#   from_port                = 5432
#   to_port                  = 5432
#   protocol                 = "tcp"
#   cidr_blocks              = ["0.0.0.0/0"]
# }

module "access_manager" {
  source = "./modules/ec2_instance"

  name        = "access-manager"
  environment = "${terraform.workspace}"

  vpc_id = "${module.idm_vpc.vpc_id}"

  ami_id            = "${local.workspace["access-manager_ami_id"]}"
  instance_type     = "${local.workspace["access-manager_instance_type"]}"
  key_name          = "${local.workspace["access-manager_key_name"]}"
  subnet_id         = "${module.idm_vpc.public_subnet_ids[0]}"
  public_ip_address = "${local.workspace["access-manager_public_association"]}"
  monitoring        = "${local.workspace["access-manager_monitoring"]}"
  storage           = "${local.workspace["access-manager_storage"]}"
}

# access manager security group rules

resource "aws_security_group_rule" "access_manager_ssh_rule" {
  security_group_id = module.access_manager.security_group_id

  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  cidr_blocks              = ["0.0.0.0/0"]
}

##################################################################
# COE EKS Test Cluster
##################################################################

module "eks_cluster_default" {
    source = "git::git@github.com:gruntwork-io/terraform-aws-eks.git//modules/eks-cluster-control-plane?ref=v0.21.0"
    
    cluster_name = var.cluster_name

    vpc_id                = module.idm_vpc.vpc_id
    vpc_master_subnet_ids = module.idm_vpc.private_subnet_ids

    enabled_cluster_log_types    = ["api", "audit", "authenticator"]
    kubernetes_version           = var.kubernetes_version
    endpoint_public_access       = var.endpoint_public_access
    endpoint_public_access_cidrs = var.endpoint_public_access_cidrs
}

module "eks_workers_default" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-eks.git//modules/eks-cluster-workers?ref=v0.21.0"

  name_prefix                = "app-workers-"
  cluster_name               = module.eks_cluster_default.eks_cluster_name
  use_cluster_security_group = var.use_cluster_security_group

  autoscaling_group_configurations = {
    asg = {
    # Set the max size to double the min size so the extra capacity can be used to do a zero-downtime deployment of updates
    # to the EKS Cluster Nodes (e.g. when you update the AMI). For docs on how to roll out updates to the cluster, see:
    # https://github.com/gruntwork-io/terraform-aws-eks/tree/master/modules/eks-cluster-workers#how-do-i-roll-out-an-update-to-the-instances
    min_size = 1
    max_size = 3

    subnet_ids = module.idm_vpc.private_subnet_ids
    tags       = []
    }
  }

  cluster_instance_ami                    = var.cluster_instance_ami
  cluster_instance_type                   = var.cluster_instance_type
  cluster_instance_keypair_name           = var.cluster_instance_keypair_name
  cluster_instance_user_data              = data.template_file.user_data.rendered
  cluster_instance_root_volume_encryption = var.cluster_instance_root_volume_encryption

  tenancy   = var.tenancy
}

resource "aws_iam_role_policy_attachment" "worker_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = module.eks_workers_default.eks_worker_iam_role_name

  # For an explanation of why this is here, see the aws_launch_configuration.eks_worker resource
  lifecycle {
    create_before_destroy = true
  }
}

module "eks_k8s_role_mapping" {
  source = "git::git@github.com:gruntwork-io/terraform-aws-eks.git//modules/eks-k8s-role-mapping?ref=v0.21.0"

  eks_worker_iam_role_arns        = [module.eks_workers_default.eks_worker_iam_role_arn]
  iam_user_to_rbac_group_mappings = var.iam_user_to_rbac_group_mapping
  config_map_labels               = map("eks-cluster", module.eks_cluster_default.eks_cluster_name)
}

data "template_file" "user_data" {
  template = file("${path.module}/user-data/user-data.sh")

  vars = {
    aws_region                = local.workspace["region"]
    eks_cluster_name          = var.cluster_name
    eks_endpoint              = module.eks_cluster_default.eks_cluster_endpoint
    eks_certificate_authority = module.eks_cluster_default.eks_cluster_certificate_authority
    dd_api_key                = local.workspace["dd_api_key"]
    dd_site                   = local.workspace["dd_site"]
  }
}

# Workaround for Terraform limitation where you cannot directly set a depends on directive or interpolate from resources
# in the provider config.
# Specifically, Terraform requires all information for the Terraform provider config to be available at plan time,
# meaning there can be no computed resources. We work around this limitation by creating a template_file data source
# that does the computation.
# See https://github.com/hashicorp/terraform/issues/2430 for more details
data "template_file" "kubernetes_cluster_endpoint" {
  template = module.eks_cluster_default.eks_cluster_endpoint
}

data "template_file" "kubernetes_cluster_ca" {
  template = module.eks_cluster_default.eks_cluster_certificate_authority
}

data "aws_eks_cluster_auth" "kubernetes_token" {
  name = module.eks_cluster_default.eks_cluster_name
}

module "datadog-agent" {
  source = "./modules/monitoring/eks-datadog-agent"

  datadog_agent_api_key = local.workspace["dd_api_key"]
  datadog_agent_app_key = local.workspace["dd_app_key"]
}