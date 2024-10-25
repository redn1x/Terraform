variable "kubernetes_namespace" {
  type        = string
  default     = "datadog"
  description = "Kubernetes namespace to deploy datadog agent."
}

variable "kubernetes_resources_name_prefix" {
  type        = string
  default     = ""
  description = "Prefix for kubernetes resources name. For example `microfocus-`"
}

variable "datadog_cluster_agent_image" {
  type        = string
  default     = "datadog/cluster-agent"
  description = "The datadog cluster agent container image"
}

variable "datadog_cluster_agent_image_tag" {
  type        = string
  default     = "latest"
  description = "The datadog cluster agent container image tag"
}

variable "datadog_agent_image" {
  type        = string
  default     = "datadog/agent"
  description = "The datadog agent container image"
}

variable "datadog_agent_image_tag" {
  type        = string
  default     = "latest"
  description = "The datadog agent container image tag"
}

variable "datadog_agent_api_key" {
  type        = string
  description = "Set the Datadog API Key related to your Organization"
}

variable "datadog_agent_app_key" {
  type        = string
  description = "Set the Datadog APP Key related to your Organization"
}

variable "datadog_agent_site" {
  type = string
  default = "datadoghq.com"
  description = "Set to 'datadoghq.eu' to send your Agent data to the Datadog EU site"
}

variable "datadog_agent_options_collect_kubernetes_events" {
  type        = bool
  default     = true
  description = "Collect Kubernetes events?"
}