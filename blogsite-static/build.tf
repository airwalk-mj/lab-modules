
resource "null_resource" "build" {
  provisioner "local-exec" {
    command = "cd ${var.app_path} && npm i && npm run build"
  }
}

resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command = "aws s3 sync ${var.app_path}/out/ s3://${var.site_domain}"
  }

  depends_on = [null_resource.build]
}
