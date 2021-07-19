
variable "project" {
  default = "Sandbox - Mark James"
}

variable "cluster_name" {
  default = "kubernetes-cluster"
}

variable "node_count" {
  default = 1
}

variable "max_node_count" {
  default = 1
}

variable "min_node_count" {
  default = 1
}

variable "admin_username" {
  default = "admin"
}

variable "admin_password" {
  default = "00000000000000000"
}

variable "machine_type" {
  default = "e2-medium"
}

variable "disk_size_gb" {
  default = "100"
}

variable "master_zone" {
  default = "europe-west2"
}

variable "additional_zones" {
  default = [
    "europe-west2-c",
    "europe-west2-d",
  ]
}

variable "min_master_version" {
  default = "0.19.0-gke.5"
}

#variable "initial_default_pool_name" {
#  default = "unused-default-pool"
#}

#variable "default_pool_name" {
#  default = "default-pool"
#}

variable "daily_maintenance_window_start_time" {
  default = "00:00"
}

variable "env" {
  default = "dev"
}

variable "kubernetes_network_name" {
  default = "lab-network"
}

variable "image_type" {
  default = "COS_CONTAINERD"
}