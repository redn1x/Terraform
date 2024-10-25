output "datadog_namespace_name" {
  description = "The name of the Datadog namespace created to store the mapping. This exists so that downstream resources can depend on the mapping being setup."
  value       = kubernetes_namespace.datadog.metadata[0].name
}