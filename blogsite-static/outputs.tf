
output "bucket_domain_name" {
  value       = module.this.enabled ? join("", aws_s3_bucket.site.*.bucket_domain_name) : ""
  description = "FQDN of bucket"
}

output "bucket_regional_domain_name" {
  value       = module.this.enabled ? join("", aws_s3_bucket.site.*.bucket_regional_domain_name) : ""
  description = "The bucket region-specific domain name"
}

output "bucket_id" {
  value       = module.this.enabled ? join("", aws_s3_bucket.site.*.id) : ""
  description = "Bucket Name (aka ID)"
}

output "bucket_arn" {
  value       = module.this.enabled ? join("", aws_s3_bucket.site.*.arn) : ""
  description = "Bucket ARN"
}

output "bucket_region" {
  value       = module.this.enabled ? join("", aws_s3_bucket.site.*.region) : ""
  description = "Bucket region"
}
