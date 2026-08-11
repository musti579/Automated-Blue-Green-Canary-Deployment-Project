module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs

}

module "rds" {
  source = "./modules/rds"

  private_subnet_ids = module.vpc.private_subnet_ids
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr

}

module "elasticache" {
source = "./modules/elasticache"

private_subnet_ids = module.vpc.private_subnet_ids
vpc_id             = module.vpc.vpc_id
vpc_cidr           = module.vpc.vpc_cidr

}

module "sqs" {
  source = "./modules/sqs"
}

module "endpoint" {
  source = "./modules/endpoint"

  vpc_id        = module.vpc.vpc_id
  private_rt    = module.vpc.private_rt  
  vpc_cidr      = module.vpc.vpc_cidr
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "ecr" {
  source = "./modules/ecr"
}

module "ecs" {
  source        = "./modules/ecs"
  db_secret_arn = module.rds.db_secret_arn
  sqs_queue_arn = module.sqs.queue_arn
  api_image_url = module.ecr.api_repository_url
  redis_url     = module.elasticache.redis_endpoint
  sqs_queue_url = module.sqs.queue_url
  worker_image_url = module.ecr.worker_repository_url
  dashboard_image_url = module.ecr.dashboard_repository_url
  api_blue_tg_arn = module.alb.api_blue_tg_arn 
  dashboard_blue_tg_arn = module.alb.dashboard_blue_tg_arn
  ecs_sg_id = module.alb.ecs_sg_id
  private_subnet_ids = module.vpc.private_subnet_ids
}

module "alb" {
  source = "./modules/alb"

  public_subnet_ids = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  certificate_arn = module.acm.certificate_arn
}

module "codedeploy" {
  source = "./modules/codedeploy"

  api_blue_tg_name  = module.alb.api_blue_tg_name
  api_green_tg_name = module.alb.api_green_tg_name
  ecs2_cluster = module.ecs.cluster_name
  listener_arn = module.alb.listener_arn
  api_service_name = module.ecs.api_service_name
  dashboard_service_name = module.ecs.dashboard_service_name
  dashboard_blue_tg_name = module.alb.dashboard_blue_tg_name
  dashboard_green_tg_name = module.alb.dashboard_green_tg_name
}

module "frontend" {
  source = "./frontend"
  frontend_certificate_arn = module.acm.frontend_certificate_arn
}

module "acm" {
  source       = "./modules/acm"
  alb_dns_name = module.alb.dns_name
  alb_zone_id  = module.alb.zone_id
  cloudfront_domain_name   = module.frontend.cloudfront_domain_name
  cloudfront_hosted_zone_id = "Z2FDTNDATAQYW2"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }
}

module "oidc" {
  source = "./modules/oidc"
}