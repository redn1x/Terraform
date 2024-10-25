locals {
  kubernetes_cluster_agent_labels = {
    "app" = "datadog-cluster-agent"
  }
  kubernetes_agent_labels = {
    "app" = "datadog-agent"
  }
}

resource "kubernetes_namespace" "datadog" {
  metadata {
    name = var.kubernetes_namespace
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Configure RBAC permissions for the Cluster Agent and node-based Agents
# EKS uses AWS IAM for user authentication and access to the cluster, 
# but it relies on Kubernetes role-based access control (RBAC) to authorize
# calls by those users to the Kubernetes API. So, for both the Cluster Agent 
# and the node-based Agents, we’ll need to set up a service account,
# a ClusterRole with the necessary RBAC permissions, and then 
# a ClusterRoleBinding that links them so that the service account can use
# those permissions.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# This creates an RBAC for EKS Cluster Agent
resource "kubernetes_service_account" "datadog_cluster_agent" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}datadog-cluster-agent-service-account"
    namespace = kubernetes_namespace.datadog.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "datadog_cluster_agent" {
  metadata {
    name   = "${var.kubernetes_resources_name_prefix}datadog-cluster-agent-role"
  }

  rule {
    api_groups = [""]
    resources = [
      "services",
      "events",
      "endpoints",
      "pods",
      "nodes",
      "componentstatuses"
    ]
    verbs = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["autoscaling"]
    resources  = ["horizontalpodautoscalers"]
    verbs      = ["list", "watch"]
  }

  rule {
    api_groups     = [""]
    resources      = ["configmaps"]
    resource_names = ["datadogtoken", "datadog-leader-election"]
    verbs          = ["get", "update"]
  }

  rule {
    non_resource_urls = [
      "/version",
      "/healthz"
    ]
    verbs = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "datadog_cluster_agent" {
  metadata {
    name   = "${kubernetes_cluster_role.datadog_cluster_agent.metadata.0.name}-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.datadog_cluster_agent.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.datadog_cluster_agent.metadata.0.namespace
    name      = kubernetes_service_account.datadog_cluster_agent.metadata.0.name
  }
}

# This creates an RBAC for EKS Node Agent
resource "kubernetes_service_account" "datadog_agent" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}datadog-agent-service-account"
    namespace = kubernetes_namespace.datadog.metadata[0].name
  }
}

resource "kubernetes_cluster_role" "datadog_agent" {
  metadata {
    name   = "${var.kubernetes_resources_name_prefix}datadog-agent-role"
  }

  rule {
    api_groups = [""]
    resources = [
      "nodes/metrics",
      "nodes/spec",
      "nodes/proxy"
    ]
    verbs = ["get"]
  }
}

resource "kubernetes_cluster_role_binding" "datadog_agent" {
  metadata {
    name   = "${kubernetes_cluster_role.datadog_agent.metadata.0.name}-role-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.datadog_agent.metadata.0.name
  }

  subject {
    kind      = "ServiceAccount"
    namespace = kubernetes_service_account.datadog_agent.metadata.0.namespace
    name      = kubernetes_service_account.datadog_agent.metadata.0.name
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Secure communication between node-based Agents and the Cluster Agent.
# ensure that the Cluster Agent and node-based Agents can securely 
# communicate with each other. The best way to do this is by creating a 
# Kubernetes secret. 
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "random_string" "datadog_token" {
  length           = 32
  override_special = "="
}

resource "kubernetes_secret" "datadog_agent" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}datadog-agent-secret"
    namespace = kubernetes_namespace.datadog.metadata[0].name
  }

  data = {
    "token" = random_string.datadog_token.result
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Create and deploy the Cluster Agent manifest.
# Deploy the Cluster Agent, create a manifest, which creates the 
# Datadog Cluster Agent Deployment and Service, links them to the 
# Cluster Agent service account we deployed above, and points to the 
# newly created secret.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "kubernetes_deployment" "datadog_cluster_agent" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}datadog-cluster-agent-deployment"
    namespace = kubernetes_namespace.datadog.metadata[0].name
    labels    = local.kubernetes_cluster_agent_labels
  }

  spec {

    selector {
      match_labels = local.kubernetes_cluster_agent_labels
    }

    template {
      metadata {
        name   = kubernetes_cluster_role.datadog_cluster_agent.metadata.0.name
        labels = local.kubernetes_cluster_agent_labels
      }

      spec {
        service_account_name = kubernetes_service_account.datadog_cluster_agent.metadata.0.name

        container {
          image             = "${var.datadog_cluster_agent_image}:${var.datadog_cluster_agent_image_tag}"
          name              = "${kubernetes_cluster_role.datadog_cluster_agent.metadata.0.name}-image"
          image_pull_policy = "Always"

          env {
            name = "DD_SITE"
            value = var.datadog_agent_site
          }

          env {
            name  = "DD_API_KEY"
            value = var.datadog_agent_api_key
          }

          env {
            name  = "DD_APP_KEY"
            value = var.datadog_agent_app_key
          }

          env {
            name  = "DD_COLLECT_KUBERNETES_EVENTS"
            value = var.datadog_agent_options_collect_kubernetes_events
          }

          env {
            name  = "DD_LEADER_ELECTION"
            value = "true"
          }

          env {
            name  = "DD_EXTERNAL_METRICS_PROVIDER_ENABLED"
            value = "true"
          }

          env {
            name = "DD_CLUSTER_AGENT_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.datadog_agent.metadata.0.name
                key  = "token"
              }
            }
          }

        }
      }
    }
  }
}

resource "kubernetes_service" "datadog_cluster_agent" {
  metadata {
    name      = "${var.kubernetes_resources_name_prefix}datadog-cluster-agent-service"
    labels    = local.kubernetes_cluster_agent_labels
  }
  spec {
    selector = local.kubernetes_cluster_agent_labels
    port {
      port     = 5505
      protocol = "TCP"
    }
  }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Deploy the node-based Agent DaemonSet.
# Deploy the node-based Agents as a DaemonSet. We use a DaemonSet here 
# because, unlike the Cluster Agent, we want to deploy the node-based 
# Agent to all of our nodes, including new ones as they are launched.
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

resource "kubernetes_daemonset" "datadog_agent" {
  depends_on = [
    kubernetes_deployment.datadog_cluster_agent,
  ]

  metadata {
    name      = "${var.kubernetes_resources_name_prefix}datadog-agent-daemonset"
  }

  spec {
    selector {
      match_labels = local.kubernetes_agent_labels
    }

    template {
      metadata {
        name   = kubernetes_cluster_role.datadog_agent.metadata.0.name
        labels = local.kubernetes_agent_labels
      }

      spec {
        service_account_name = kubernetes_service_account.datadog_agent.metadata.0.name

        container {
          image             = "${var.datadog_agent_image}:${var.datadog_agent_image_tag}"
          name              = "${kubernetes_cluster_role.datadog_agent.metadata.0.name}-image"
          image_pull_policy = "Always"
        
          port {
            container_port = 8125
            name           = "dogstatsdport"
            protocol       = "UDP"
          }

          port {
            container_port = 8126
            name           = "traceport"
            protocol       = "TCP"
          }

          env {
            name = "DD_SITE"
            value = var.datadog_agent_site
          }

          env {
            name  = "DD_API_KEY"
            value = var.datadog_agent_api_key
          }

          env {
            name  = "DD_COLLECT_KUBERNETES_EVENTS"
            value = var.datadog_agent_options_collect_kubernetes_events
          }

          env {
            name  = "DD_LEADER_ELECTION"
            value = "true"
          }

          env {
            name  = "KUBERNETES"
            value = "true"
          }

          env {
            name = "DD_KUBERNETES_KUBELET_HOST"
            value_from {
              field_ref {
                field_path = "status.hostIP"
              }
            }
          }

          env {
            name  = "DD_CLUSTER_AGENT_ENABLED"
            value = "true"
          }

          env {
            name = "DD_CLUSTER_AGENT_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.datadog_agent.metadata.0.name
                key  = "token"
              }
            }
          }

          resources {
            requests {
              memory = "256Mi"
              cpu    = "200m"
            }

            limits {
              memory = "256Mi"
              cpu    = "200m"
            }
          }

          volume_mount {
            name       = "dockersocket"
            mount_path = "/var/run/docker.sock"
          }

          volume_mount {
            name       = "procdir"
            mount_path = "/host/proc"
            read_only  = true
          }

          volume_mount {
            name       = "cgroups"
            mount_path = "/host/sys/fs/cgroup"
            read_only  = true
          }

          liveness_probe {
            exec {
              command = ["./probe.sh"]
            }

            initial_delay_seconds = 15
            period_seconds        = 15
          }
        }

        volume {
          name = "dockersocket"
          host_path {
            path = "/var/run/docker.sock"
          }
        }

        volume {
          name = "procdir"
          host_path {
            path = "/proc"
          }
        }

        volume {
          name = "cgroups"
          host_path {
            path = "/sys/fs/cgroup"
          }
        }

      }
    }
  }
}