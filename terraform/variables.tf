variable "aws_region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "project_name" {
  description = "Project name used for tagging"
  default     = "devops-code-challenge3"
}

variable "key_name" {
  description = "Name of your AWS key pair"
  default     = "devops-3-key"
}