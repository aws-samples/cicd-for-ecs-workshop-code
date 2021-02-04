module "front_pipeline" {
  source = "./modules/service-pipeline"

  source_repo_name = "tf-front"
  source_repo_branch = "master"
  terraform_bucket_name = aws_s3_bucket.terraform_bucket.bucket
  terraform_bucket_arn = aws_s3_bucket.terraform_bucket.arn
}

output "front_source_repo_clone_url_http" {
  value = module.front_pipeline.source_repo_clone_url_http
}

output "front_pipeline_url" {
  value = module.front_pipeline.pipeline_url
}