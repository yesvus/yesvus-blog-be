# Terraform Infrastructure

This directory provisions AWS infrastructure for the FastAPI blog backend.

## Structure

- `modules/network`: VPC, subnets, route tables, security groups
- `modules/ecr`: ECR repository + lifecycle policy
- `modules/storage_cdn`: S3 image bucket + CloudFront distribution
- `modules/rds_postgres`: RDS PostgreSQL instance
- `modules/ecs_service`: ECS Fargate cluster/service + ALB + IAM + logs
- `envs/dev`: development stack composition
- `envs/prod`: production stack composition

## Environment Defaults

- Region: `eu-central-1`
- Dev ECS desired count: `0` (cost control)
- Prod ECS desired count: `1`
- No NAT gateway; ECS tasks run with public IP in public subnets

## Local Terraform Usage

Example for dev:

```bash
cd infra/envs/dev
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply -auto-approve
```

Required variables:

- `image_uri`
- `s3_bucket_name`
- `db_password`
- `secret_key`

## Deployment Strategy

CI/CD uses a migration-first rollout:

1. Apply infra with service scaled to `0`
2. Build and push Docker image to ECR
3. Apply new task definition with new image (still scaled to `0`)
4. Run one-off ECS task: `uv run alembic upgrade head`
5. Apply final desired count

## Rollback Runbook

1. Identify previous container image tag in ECR.
2. Re-run deploy workflow with previous `image_uri`.
3. If schema rollback is required and safe, execute one-off task with:
   `uv run alembic downgrade -1`
4. Validate `/health` and `/ready` via ALB endpoint.
