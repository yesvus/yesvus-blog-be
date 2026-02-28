terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "${var.project_name}-dev"
  tags = merge(var.tags, {
    Environment = "dev"
    Project     = var.project_name
  })
}

module "network" {
  source = "../../modules/network"

  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = slice(data.aws_availability_zones.available.names, 0, 2)
  container_port       = var.container_port
  tags                 = local.tags
}

module "ecr" {
  source = "../../modules/ecr"

  name = "${local.name}-api"
  tags = local.tags
}

module "storage" {
  source = "../../modules/storage_cdn"

  name                   = local.name
  bucket_name            = var.s3_bucket_name
  enable_versioning      = false
  cors_allowed_origins   = var.cors_allowed_origins
  cloudfront_price_class = "PriceClass_100"
  tags                   = local.tags
}

module "rds" {
  source = "../../modules/rds_postgres"

  name                    = local.name
  private_subnet_ids      = module.network.private_subnet_ids
  rds_security_group_id   = module.network.rds_security_group_id
  db_name                 = var.db_name
  db_username             = var.db_username
  db_password             = var.db_password
  instance_class          = var.db_instance_class
  backup_retention_period = 1
  deletion_protection     = false
  skip_final_snapshot     = true
  tags                    = local.tags
}

module "ecs" {
  source = "../../modules/ecs_service"

  name                  = local.name
  aws_region            = var.aws_region
  vpc_id                = module.network.vpc_id
  public_subnet_ids     = module.network.public_subnet_ids
  alb_security_group_id = module.network.alb_security_group_id
  ecs_security_group_id = module.network.ecs_security_group_id
  image_uri             = var.image_uri
  container_name        = "api"
  container_port        = var.container_port
  task_cpu              = var.task_cpu
  task_memory           = var.task_memory
  desired_count         = var.ecs_desired_count
  health_check_path     = "/ready"
  s3_bucket_arn         = module.storage.bucket_arn
  environment = {
    APP_ENV                      = "production"
    APP_HOST                     = "0.0.0.0"
    APP_PORT                     = tostring(var.container_port)
    DATABASE_URL                 = "postgresql+asyncpg://${var.db_username}:${var.db_password}@${module.rds.address}:${module.rds.port}/${module.rds.db_name}"
    SECRET_KEY                   = var.secret_key
    ALGORITHM                    = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES  = "30"
    AWS_REGION                   = var.aws_region
    S3_BUCKET_NAME               = module.storage.bucket_name
    CLOUDFRONT_DOMAIN            = module.storage.cloudfront_domain_name
    MEDIA_PRESIGN_EXPIRE_SECONDS = "900"
    MAX_UPLOAD_SIZE_BYTES        = "10485760"
    ALLOWED_IMAGE_TYPES          = "image/jpeg,image/png,image/webp"
  }
  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${local.name}-api-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "High API 5xx responses"

  dimensions = {
    LoadBalancer = module.ecs.alb_arn_suffix
    TargetGroup  = module.ecs.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "api_latency" {
  alarm_name          = "${local.name}-api-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.5
  alarm_description   = "High API latency"

  dimensions = {
    LoadBalancer = module.ecs.alb_arn_suffix
    TargetGroup  = module.ecs.target_group_arn_suffix
  }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks" {
  alarm_name          = "${local.name}-ecs-running-tasks"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "RunningTaskCount"
  namespace           = "AWS/ECS"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "ECS running task count unexpectedly low"

  dimensions = {
    ClusterName = module.ecs.cluster_name
    ServiceName = module.ecs.service_name
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  alarm_name          = "${local.name}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 60
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "RDS CPU high"

  dimensions = {
    DBInstanceIdentifier = "${local.name}-postgres"
  }
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage" {
  alarm_name          = "${local.name}-rds-free-storage"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 2147483648
  alarm_description   = "RDS free storage low"

  dimensions = {
    DBInstanceIdentifier = "${local.name}-postgres"
  }
}
