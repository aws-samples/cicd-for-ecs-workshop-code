
# Inputs

variable "environment_name" {
  description = "Name of environment to deploy to."
  type = string
}

variable "service_name" {
  description = "Service name"
  type = string
}

variable "path" {
  description = "Resource path to mount service on."
  type = string
}

variable "priority" {
  description = "Listener rule priority"
  type = number
}

variable "desired_count" {
  description = "Desired count"
  type = number
}

variable "container_name" {
  description = "Name of container inside task."
  type = string
}

variable "container_port" {
  description = "Port of container inside task."
  type = number
}


variable "container_command" {
  description = "Command line run options for container."
  type = list(string)
}

variable "log_group_name" {
  description = "Name of log group."
  type = string
}

variable "ecr_repo_name" {
  description = "Image repo name"
  type = string
}

variable "ecr_image_tag" {
  description = "Image tag"
  type = string
}

variable "namespace_id" {
  description = "Namespace"
  type = string
}
