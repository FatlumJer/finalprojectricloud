output "kube_config" {
  value     = module.aks.kube_config
  sensitive = true
}

output "cluster_name" {
  value = var.cluster_name
}