# EKS Cluster - Datadog Module

This Terraform Module deploys a Datadog Cluster/Node agent to your EKS Cluster. [Monitoring your EKS cluster with Datadog](https://www.datadoghq.com/blog/eks-monitoring-datadog/).

1. Configure RBAC permissions for the Cluster Agent and node-based Agents
1. Creates secure communication between node-based Agents and the Cluster Agent
1. Create and deploy the Cluster Agents
1. Deploy the node-based Agent as DaemonSet
   

## What resources are created?
1. Kubernetes Namespace
1. Kubernetes Service Account (Cluster/Node)
1. Kubernetes Cluster Role (Cluster/Node)
1. Kubernetes Cluster Role Binding (Cluster/Node)
1. Kubernetes Secret
1. Kubernetes Deployment (Cluster)
1. Kubernetes Service (Cluster)
1. Kubernetes Daemonset (Node)


## How do you use this module?

1. See the root README for instructions on using Terraform modules.
1. This module uses the kubernetes provider
1. This provider must depend on the EKS cluster being setup.
1. See Usage for the Example Usage.
1. See variables.tf for all the variables you can set on this module.
1. See outputs.tf for all the variables that are outputed by this module.



## Usage

```
module "eks_cluster" {
    # your eks-cluster-control-plane config here
}

data "template_file" "kubernetes_cluster_endpoint" {
  template = module.eks_cluster.eks_cluster_endpoint
}

data "template_file" "kubernetes_cluster_ca" {
  template = module.eks_cluster.eks_cluster_certificate_authority
}

data "aws_eks_cluster_auth" "kubernetes_token" {
  name = module.eks_cluster.eks_cluster_name
}

# This kubernetes provider must depend on the EKS cluster[module.eks_cluster]
provider "kubernetes" {
  version = "= 1.11.1"

  load_config_file       = false
  host                   = data.template_file.kubernetes_cluster_endpoint.rendered
  cluster_ca_certificate = base64decode(data.template_file.kubernetes_cluster_ca.rendered)
  token                  = data.aws_eks_cluster_auth.kubernetes_token.token
}

module "datadog-agent" {
  source = "..."

  datadog_agent_api_key = <YOUR_DATADOG_API_KEY>
  datadog_agent_app_key = <YOUR_DATADOG_APP_KEY>
  kubernetes_resources_name_prefix = "mf-eks-"
}

```



### Deploy the Terraform code

* See the [root README](/README.md) for instructions on how to deploy the Terraform code in this repo.
* See [variables.tf](./variables.tf) for all the variables you can set on this module.



## What is Datadog?

[Datadog](https://www.datadoghq.com/) is a monitoring service for cloud-scale applications, providing monitoring of servers, databases, tools, and services, through a SaaS-based data analytics platform.