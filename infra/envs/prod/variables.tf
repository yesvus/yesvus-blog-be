variable "project_name" {
  type    = string
  default = "yesvus-blog"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "vpc_cidr" {
  type    = string
  default = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.30.101.0/24", "10.30.102.0/24"]
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "task_cpu" {
  type    = number
  default = 256
}

variable "task_memory" {
  type    = number
  default = 512
}

variable "ecs_desired_count" {
  type    = number
  default = 1
}

variable "db_name" {
  type    = string
  default = "blog"
}

variable "db_username" {
  type    = string
  default = "blog"
}

variable "db_password" {
  type      = string
  sensitive = true
}

variable "db_instance_class" {
  type    = string
  default = "db.t4g.micro"
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "image_uri" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "cors_allowed_origins" {
  type    = list(string)
  default = ["*"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
