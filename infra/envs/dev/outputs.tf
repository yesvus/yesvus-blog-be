output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "cloudfront_domain_name" {
  value = module.storage.cloudfront_domain_name
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}

output "ecs_service_name" {
  value = module.ecs.service_name
}

output "ecs_task_definition_arn" {
  value = module.ecs.task_definition_arn
}

output "ecs_task_definition_family" {
  value = module.ecs.task_definition_family
}

output "ecs_container_name" {
  value = module.ecs.container_name
}

output "public_subnet_ids" {
  value = module.network.public_subnet_ids
}

output "ecs_security_group_id" {
  value = module.network.ecs_security_group_id
}
