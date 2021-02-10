provider "aws" {
  profile = "default"
  version = "~> 2.64"
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

 # Inputs

variable "source_repo_name" {
    description = "Source repo name"
    type = string
}

variable "source_repo_branch" {
    description = "Source repo branch"
    type = string
}

variable "terraform_bucket_arn" {
  description = "Terraform backend bucket"
  type = string
}

variable "terraform_bucket_name" {
  description = "Terraform backend bucket name"
  type = string
}


# Outputs

output "source_repo_clone_url_http" {
  value = "${aws_codecommit_repository.source_repo.clone_url_http}"
}

output "pipeline_url" {
  value = "https://console.aws.amazon.com/codepipeline/home?region=${data.aws_region.current.name}#/view/${aws_codepipeline.pipeline.id}"
}
  

# Resources


# Code Commit repo

resource "aws_codecommit_repository" "source_repo" {
  repository_name = var.source_repo_name
  description     = "Service config repository"
}


# Trigger role and event rule to trigger pipeline

resource "aws_iam_role" "trigger_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  path = "/"
}

resource "aws_iam_policy" "trigger_policy" {
  description = "Policy to allow rule to invoke pipeline"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "codepipeline:StartPipelineExecution"
      ],
      "Effect": "Allow",
      "Resource": "${aws_codepipeline.pipeline.arn}"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "trigger-attach" {
  role       = aws_iam_role.trigger_role.name
  policy_arn = aws_iam_policy.trigger_policy.arn
}

resource "aws_cloudwatch_event_rule" "trigger_rule" {
  description = "Trigger the pipeline on change to repo/branch"
  event_pattern = <<PATTERN
{
  "source": [ "aws.codecommit" ],
  "detail-type": [ "CodeCommit Repository State Change" ],
  "resources": [ "${aws_codecommit_repository.source_repo.arn}" ],
  "detail": {
    "event": [ "referenceCreated", "referenceUpdated" ],
    "referenceType": [ "branch" ],
    "referenceName": [ "${var.source_repo_branch}" ]
  }
}
PATTERN
  role_arn = aws_iam_role.trigger_role.arn
  is_enabled = true

}

resource "aws_cloudwatch_event_target" "target_pipeline" {
  rule      = aws_cloudwatch_event_rule.trigger_rule.name
  arn       = aws_codepipeline.pipeline.arn
  role_arn  = aws_iam_role.trigger_role.arn
  target_id = "${var.source_repo_name}-${var.source_repo_branch}-pipeline"
}


# Bucket for pipeline


resource "aws_s3_bucket" "artifact_bucket" {
}

# Codebuild role

resource "aws_iam_role" "codebuild_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  path = "/"
}

resource "aws_iam_policy" "codebuild_policy" {
  description = "Policy to allow codebuild to execute build spec"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents",
        "ecr:GetAuthorizationToken"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "cloudformation:ListExports"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": "${var.terraform_bucket_arn}"
    },  
    {
      "Action": [
        "s3:GetObject", "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${var.terraform_bucket_arn}/${var.source_repo_name}-${var.source_repo_branch}"
    },    
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.artifact_bucket.arn}/*"
    },
    {
      "Action": [
        "ecr:*",
        "ecs:*",
        "iam:*",
        "Logs:*",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DescribeRules", "elasticloadbalancing:DescribeTags",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetGroupAttributes",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:ModifyTargetGroupAttributes",
        "elasticloadbalancing:SetRulePriorities",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:RemoveTags",
        "servicediscovery:CreateService",
        "servicediscovery:GetService",
        "servicediscovery:UpdateService",
        "servicediscovery:DeleteService",
        "servicediscovery:ListTagsForResource",
        "cloudwatch:GetDashboard",
        "cloudwatch:PutDashboard",
        "cloudwatch:PutMetricData",
        "cloudwatch:DeleteDashboards"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codebuild-attach" {
  role       = aws_iam_role.codebuild_role.name
  policy_arn = aws_iam_policy.codebuild_policy.arn
}

# CodeBuild Project to invoke Terraform


resource "aws_codebuild_project" "codebuild" {
  depends_on = [
    aws_codecommit_repository.source_repo
  ]
  name          = "codebuild-${var.source_repo_name}-${var.source_repo_branch}"
  service_role  = aws_iam_role.codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:2.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = false
    image_pull_credentials_type = "CODEBUILD"
    environment_variable {
      name = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    environment_variable {
      name = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.name
    }
    environment_variable {
      name = "TF_VERSION"
      value = "0.14.6"
    }
    
  }
  source {
    type = "CODEPIPELINE"
    buildspec = <<BUILDSPEC
version: 0.2

phases:
  install:
    commands:
      - "cd /usr/bin"
      - "curl -s -qL -o terraform.zip https://releases.hashicorp.com/terraform/$${TF_VERSION}/terraform_$${TF_VERSION}_linux_amd64.zip"
      - "unzip -o terraform.zip"
  build:
    commands:
      - echo Terraform deployment started on `date`
      - cd "$CODEBUILD_SRC_DIR"
      - terraform init -input=false --backend-config="bucket=${var.terraform_bucket_name}" --backend-config="key=${var.source_repo_name}-${var.source_repo_branch}" --backend-config="region=${data.aws_region.current.name}"
      - terraform apply -input=false -var-file=./terraform.tfvars -auto-approve
  post_build:
    commands:
      - echo "Terraform completed on `date`"
artifacts:
  files:
    - '**/*'
BUILDSPEC
  }
}        


# Codepipeline role

resource "aws_iam_role" "codepipeline_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
  path = "/"
}

resource "aws_iam_policy" "codepipeline_policy" {
  description = "Policy to allow codepipeline to execute"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject", "s3:GetObjectVersion", "s3:PutObject",
        "s3:GetBucketVersioning"
      ],
      "Effect": "Allow",
      "Resource": "${aws_s3_bucket.artifact_bucket.arn}/*"
    },
    {
      "Action" : [
        "codebuild:StartBuild", "codebuild:BatchGetBuilds",
        "cloudformation:*",
        "iam:PassRole",
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codepipeline-attach" {
  role       = aws_iam_role.codepipeline_role.name
  policy_arn = aws_iam_policy.codepipeline_policy.arn
}


# Pipeline


resource "aws_codepipeline" "pipeline" {
  depends_on = [
    aws_codebuild_project.codebuild
  ]
  name     = "${var.source_repo_name}-${var.source_repo_branch}-Pipeline"
  role_arn = aws_iam_role.codepipeline_role.arn
  artifact_store {
    location = aws_s3_bucket.artifact_bucket.bucket
    type     = "S3"
  }

  stage {
    name = "Source"
    action {
      name = "Source"
      category = "Source"
      owner = "AWS"
      version = "1"
      provider = "CodeCommit"
      output_artifacts = ["SourceOutput"] 
      run_order = 1
      configuration = {
        RepositoryName = "${var.source_repo_name}"
        BranchName = "${var.source_repo_branch}"
        PollForSourceChanges = "false"
      }
    }
  }

  stage {
    name = "Build"
    action {
      name = "Build"
      category = "Build"
      owner = "AWS"
      version = "1"
      provider = "CodeBuild"
      input_artifacts = ["SourceOutput"]
      output_artifacts = ["BuildOutput"]
      run_order = 1
      configuration = {
        ProjectName = "${aws_codebuild_project.codebuild.id}"
      }
    }
  }
}