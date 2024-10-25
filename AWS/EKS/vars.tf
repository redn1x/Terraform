# ---------------------------------------------------------------------------------------------------------------------
# MODULE PARAMETERS
# These variables are expected to be passed in by the operator
# ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = "eks-coe-cluster"
}

# variable "autoscaling_group_configurations" {
#   description = "Configure one or more Auto Scaling Groups (ASGs) to manage the EC2 instances in this cluster."

#   # Each configuration must be keyed by a unique string that will be used as a suffix for the ASG name.
#   #
#   # Example:
#   # autoscaling_group_configurations = {
#   #   "asg1" = {
#   #     min_size   = 1
#   #     max_size   = 3
#   #     subnet_ids = [data.terraform_remote_state.vpc.outputs.private_app_subnet_ids[0]]
#   #     tags       = []
#   #   },
#   #   "asg2" = {
#   #     min_size   = 1
#   #     max_size   = 3
#   #     subnet_ids = [data.terraform_remote_state.vpc.outputs.private_app_subnet_ids[1]]
#   #     tags       = []
#   #   }
#   # }
#   type = map(object({
#     # The minimum number of EC2 Instances representing workers launchable for this EKS Cluster. Useful for auto-scaling limits.
#     min_size = number
#     # The maximum number of EC2 Instances representing workers that must be running for this EKS Cluster.
#     # We recommend making this at least twice the min_size, even if you don't plan on scaling the cluster up and down, as the extra capacity will be used to deploy udpates to the cluster.
#     max_size = number

#     # A list of the subnets into which the EKS Cluster's worker nodes will be launched.
#     # These should usually be all private subnets and include one in each AWS Availability Zone.
#     # NOTE: If using a cluster autoscaler, each ASG may only belong to a single availability zone.
#     subnet_ids = list(string)

#     # Custom tags to apply to the EC2 Instances in this ASG.
#     # Each item in this list should be a map with the parameters key, value, and propagate_at_launch.
#     #
#     # Example:
#     # [
#     #   {
#     #     key = "foo"
#     #     value = "bar"
#     #     propagate_at_launch = true
#     #   },
#     #   {
#     #     key = "baz"
#     #     value = "blah"
#     #     propagate_at_launch = true
#     #   }
#     # ]
#     tags = list(object({
#       key                 = string
#       value               = string
#       propagate_at_launch = bool
#     }))
#   }))
# }

variable "cluster_instance_type" {
  description = "The type of instances to run in the EKS cluster (e.g. t3.medium)"
  type        = string
  default     = "t3.medium"
}

variable "cluster_instance_ami" {
  description = "The AMI to run on each instance in the EKS cluster. You can build the AMI using the Packer template under packer/build.json."
  type        = string
  default     = "ami-084dfbfd9e9f15c2d"
}

variable "cluster_instance_keypair_name" {
  description = "The name of the Key Pair that can be used to SSH to each instance in the EKS cluster"
  type        = string
  default     = ""
}

# variable "vpc_name" {
#   description = "The name of the VPC in which to run the EKS cluster (e.g. stage, prod)"
#   type        = string
# }

# variable "terraform_state_aws_region" {
#   description = "The AWS region of the S3 bucket used to store Terraform remote state"
#   type        = string
# }

variable "iam_user_to_rbac_group_mapping" {
  description = "Mapping of IAM user ARNs to Kubernetes RBAC groups that grant permissions to the user."
  type = map(list(string))

  default = {
    "arn:aws:iam::621270530972:user/klarenz.melchor@microfocus.com" = ["system:masters"],
    "arn:aws:iam::621270530972:user/hazel.yap@microfocus.com" = ["system:masters"],
    "arn:aws:iam::621270530972:user/gerold.mercadero@microfocus.com" = ["system:masters"]
  }

  # Example:
  # {
  #    "arn:aws:iam::ACCOUNT_ID:user/admin-user" = ["system:masters"]
  # }
}

variable "tenancy" {
  description = "The tenancy of this server. Must be one of: default, dedicated, or host."
  type        = string
  default     = "default"
}

variable "allow_ssh" {
  description = "Set to true to allow SSH access to this EKS workers from the OpenVPN server."
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Version of Kubernetes to use. Refer to EKS docs for list of available versions (https://docs.aws.amazon.com/eks/latest/userguide/platform-versions.html)."
  type        = string
  default     = "1.17"
}

variable "restricted_control_plane_az" {
  description = "Some availability zones in specific regions are known to lack support for EKS control planes. This list is used to mark those AZs where the control plane should not be deployed into."
  type        = list(string)
  default     = [
    "us-east-1e",
  ]
}

variable "cluster_instance_root_volume_encryption" {
  description = "Whether to enable encryption for the root volume of each of the EKS Cluster's Worker Nodes"
  type        = bool
  default     = true
}

variable "use_cluster_security_group" {
  description = "Whether or not to attach the EKS managed cluster security group to the worker nodes for control plane and cross worker network management. Avoiding the cluster security group allows you to better isolate worker nodes at the network level (E.g., disallowing free flowing traffic between Fargate Pods and self managed workers). It is recommended to use the cluster security group for most use cases. Refer to the module README for more information."
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether or not to enable public API endpoints which allow access to the Kubernetes API from outside of the VPC."
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "A list of CIDR blocks that should be allowed network access to the Kubernetes public API endpoint. When null or empty, allow access from the whole world (0.0.0.0/0). Note that this only restricts network reachability to the API, and does not account for authentication to the API."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "terraform_state_kms_master_key" {
  description = "Path base name of the kms master key to use. This should reflect what you have in your infrastructure-live folder."
  type = string
  default = "kms-master-key"
}
