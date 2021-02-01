
terraform {
  backend "gcs" {}
}

resource "google_compute_network" "kubernetes_network" {
  name                    = var.kubernetes_network_name
  auto_create_subnetworks = "true"
  project                 = var.project
}

resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
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
    machine_type = "e2-medium"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}



#resource "google_container_cluster" "kubernetes_cluster" {
#  name               = var.cluster_name
#  min_master_version = var.min_master_version
#  project            = var.project
#  network            = google_compute_network.kubernetes_network.name

#  lifecycle {
#    ignore_changes = [node_pool]
#  }

  #node_pool {
  #  name = var.default_pool_name
  #  
  #}

#  master_auth {
#    username = var.admin_username
#    password = var.admin_password
#  }

#  maintenance_policy {
#    daily_maintenance_window {
#      start_time = var.daily_maintenance_window_start_time
#    }
#  }
#}

#resource "google_container_node_pool" "default_pool" {
#  name       = var.default_pool_name
#  cluster    = google_container_cluster.kubernetes_cluster.name
#  node_count = var.node_count
#  project    = var.project
  
#  node_config {
#    machine_type = var.machine_type
#    disk_size_gb = var.disk_size_gb
#    image_type   = var.image_type

#    oauth_scopes = [
#      "https://www.googleapis.com/auth/logging.write",
#      "https://www.googleapis.com/auth/monitoring",
#      "https://www.googleapis.com/auth/compute",
#      "https://www.googleapis.com/auth/devstorage.read_only",
#      "https://www.googleapis.com/auth/service.management.readonly",
#      "https://www.googleapis.com/auth/servicecontrol",
#      "https://www.googleapis.com/auth/trace.append"
#    ]
#  }

#  autoscaling {
#    min_node_count = var.min_node_count
#    max_node_count = var.max_node_count
#  }
#}