output "kubernetes_api_endpoint" {
  value = "${google_container_cluster.kubernetes_cluster.endpoint}"
}

output "client_certificate" {
  value = "${google_container_cluster.kubernetes_cluster.master_auth.0.client_certificate}"
}

output "client_key" {
  value = "${google_container_cluster.kubernetes_cluster.master_auth.0.client_key}"
}

output "cluster_ca_certificate" {
  value = "${google_container_cluster.kubernetes_cluster.master_auth.0.cluster_ca_certificate}"
}