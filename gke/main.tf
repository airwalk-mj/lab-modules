
terraform {
  backend "gcs" {}
}

resource "google_compute_network" "kubernetes_network" {
  name                    = var.kubernetes_network_name
  auto_create_subnetworks = "true"
  project                 = var.project
}

resource "google_service_account" "default" {
  project      = var.project
  account_id   = var.project
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
  project  = var.project
  name     = var.project
  location = var.master_zone

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = var.project
  location   = var.master_zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count

  node_config {
    preemptible  = true
    machine_type = var.machine_type
    image_type   = "cos_containerd"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
