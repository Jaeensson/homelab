output "kubeconfig" {
  description = "Kubernetes kubeconfig for the cluster"
  sensitive   = true
  value       = talos_cluster_kubeconfig.this.kubeconfig_raw
}

output "talosconfig" {
  description = "Talos client configuration"
  sensitive   = true
  value       = data.talos_client_configuration.this.talos_config
}

output "controlplane_ip" {
  description = "Controlplane node IP"
  value       = var.controlplane_ip
}

output "worker_ips" {
  description = "Worker node IPs"
  value       = var.worker_ips
}

output "cluster_endpoint" {
  description = "Kubernetes API endpoint"
  value       = "https://${var.controlplane_ip}:6443"
}
