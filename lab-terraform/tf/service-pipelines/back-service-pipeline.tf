module "back_pipeline" {
  source = "./modules/service-pipeline"

  source_repo_name = "tf-back"
  source_repo_branch = "master"
  terraform_bucket_name = aws_s3_bucket.terraform_bucket.bucket
  terraform_bucket_arn = aws_s3_bucket.terraform_bucket.arn
}

output "back_source_repo_clone_url_http" {
  value = module.back_pipeline.source_repo_clone_url_http
}

output "back_pipeline_url" {
  value = module.back_pipeline.pipeline_url
}