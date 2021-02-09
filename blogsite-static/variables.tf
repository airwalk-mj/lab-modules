
variable "aws_region" {
  default = "eu-west-2"
}

variable "site_domain" {
  default = "lab.airwalkconsulting.io"
}

variable "subject_alt_names" {
  default = ["blog.lab.airwalkconsulting.io",  "*.blog.lab.airwalkconsulting.io",]
}

variable "zone_id" {
  default = "Z064458838N2OGDPML4NA"
}

variable "bucket_index_document" {
  default = "index.html"
}

variable "bucket_error_document" {
  default = "404.html"
}

variable "default_root_object" {
  default = "index.html"
}

variable "min_ttl" {
  default = "0"
}

variable "max_ttl" {
  default = "31536000"
}

variable "default_ttl" {
  default = "86400"
}

variable "custom_error_response" {
  default = "err....awkward"
}

variable "app_path" {
  default = "my-app"
}
