output "kubeconfig" {
  description = "Kubernetes kubeconfig for the cluster"
  sensitive   = true
  value       = module.talos_cluster.kubeconfig
}

output "talosconfig" {
  description = "Talos client configuration"
  sensitive   = true
  value       = module.talos_cluster.talosconfig
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = module.talos_cluster.cluster_endpoint
}

output "controlplane_ip" {
  description = "Controlplane node IP"
  value       = module.talos_cluster.controlplane_ip
}

output "worker_ips" {
  description = "Worker node IPs"
  value       = module.talos_cluster.worker_ips
}
