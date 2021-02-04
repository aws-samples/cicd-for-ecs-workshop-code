module "middle_pipeline" {
  source = "./modules/service-pipeline"

  source_repo_name = "tf-middle"
  source_repo_branch = "master"
  terraform_bucket_name = aws_s3_bucket.terraform_bucket.bucket
  terraform_bucket_arn = aws_s3_bucket.terraform_bucket.arn
}

output "middle_source_repo_clone_url_http" {
  value = module.middle_pipeline.source_repo_clone_url_http
}

output "middle_pipeline_url" {
  value = module.middle_pipeline.pipeline_url
}