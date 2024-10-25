#!/bin/bash
#
# This script is meant to be run in the User Data of each EKS instance. This does the following:
#
# 1. Register the instance with the EKS cluster control plane.
# 1. Set node labels that map to the EC2 tags associated with the instance.
#
# Note, this script:
#
# 1. Assumes it is running in the AMI built from the ../packer/eks-node.json Packer template.
# 2. Has a number of variables filled in using Terraform interpolation.

set -e

# Send the log output from this script to user-data.log, syslog, and the console
# From: https://alestic.com/2010/12/ec2-user-data-output/
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

function start_fail2ban {
  echo "Starting fail2ban"
  /etc/user-data/configure-fail2ban-cloudwatch/configure-fail2ban-cloudwatch.sh --cloudwatch-namespace Fail2Ban
}

function configure_eks_instance {
  local -r aws_region="$1"
  local -r eks_cluster_name="$2"
  local -r eks_endpoint="$3"
  local -r eks_certificate_authority="$4"

  local -r node_labels="$(map-ec2-tags-to-node-labels)"

  start_fail2ban

  echo "Running eks bootstrap script to register instance to cluster"
  /etc/eks/bootstrap.sh \
    --apiserver-endpoint "$eks_endpoint" \
    --b64-cluster-ca "$eks_certificate_authority" \
    --kubelet-extra-args "--node-labels=\"$node_labels\"" \
    "$eks_cluster_name"
}

function install_ssm_agent {
  local -r aws_region="$1"

  yum install -y https://s3.${aws_region}.amazonaws.com/amazon-ssm-${aws_region}/latest/linux_amd64/amazon-ssm-agent.rpm
  systemctl enable amazon-ssm-agent
  systemctl start amazon-ssm-agent
}

function install_dd_agent {
  local -r dd_api_key="$1"
  local -r dd_site="$2"

  DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=${dd_api_key} DD_SITE=${dd_site} bash -c "$(curl -L https://s3.amazonaws.com/dd-agent/scripts/install_script.sh)"
  systemctl enable datadog-agent
  systemctl start datadog-agent
}
# These variables are set by Terraform interpolation
configure_eks_instance "${aws_region}" "${eks_cluster_name}" "${eks_endpoint}" "${eks_certificate_authority}"

# Install DD Agent
install_dd_agent "${dd_api_key}" "${dd_site}" 

# Install SSM Agent
install_ssm_agent "${aws_region}"