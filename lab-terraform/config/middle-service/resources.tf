# Set up data source for CloudFormation exports

data "aws_cloudformation_export" "cluster_name" {
  name = "${var.environment_name}:ClusterName"
}

data "aws_cloudformation_export" "container_security_group" {
  name = "${var.environment_name}:ContainerSecurityGroup"
}

data "aws_cloudformation_export" "private_subnet_one" {
  name = "${var.environment_name}:PrivateSubnetOne"
}

data "aws_cloudformation_export" "private_subnet_two" {
  name = "${var.environment_name}:PrivateSubnetTwo"
}

# Resources

# Log group

resource "aws_cloudwatch_log_group" "log_group" {
  name = var.log_group_name
  retention_in_days = 7
}


# Service Registry


resource "aws_service_discovery_service" "service" {
  name = var.service_name
  namespace_id = var.namespace_id

  dns_config {
    namespace_id = var.namespace_id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "WEIGHTED"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

# Task definition

resource "aws_iam_role" "execution_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
  path = "/"
}


resource "aws_iam_role_policy_attachment" "execution-attach" {
  role       = aws_iam_role.execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_ecs_task_definition" "taskdef" {
  family = var.service_name
  network_mode = "awsvpc"
  requires_compatibilities = [ "EC2", "FARGATE"]
  cpu = 256
  memory = 512
  execution_role_arn = aws_iam_role.execution_role.arn
  container_definitions = <<DEFINITION
[
  {
    "name": "${var.container_name}",
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${var.ecr_repo_name}:${var.ecr_image_tag}",
    "command": ${jsonencode(var.container_command)},
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-group": "${var.log_group_name}",
        "awslogs-stream-prefix": "${var.ecr_image_tag}"
      }
    },
    "portMappings": [
      {
        "containerPort": ${var.container_port}
      }
    ],
    "environment": [{
      "name": "AWS_REGION",
      "value": "${data.aws_region.current.name}"
    }],
    "essential": true
  }
]
DEFINITION
}


# ECS Service

resource "aws_ecs_service" "service" {
  cluster         = data.aws_cloudformation_export.cluster_name.value
  name            = var.service_name
  task_definition = aws_ecs_task_definition.taskdef.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [ data.aws_cloudformation_export.container_security_group.value ]
    subnets = [
      data.aws_cloudformation_export.private_subnet_one.value,
      data.aws_cloudformation_export.private_subnet_two.value
    ]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.service.arn
    container_name = var.container_name
  }
  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50
}