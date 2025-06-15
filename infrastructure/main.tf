module "vpc" {
  source = "./modules/vpc"

  cidr_block = "10.0.0.0/16"
  availability_zones = ["eu-west-1a", "eu-west-1b"]
}

module "iam" {
  source = "./modules/iam"
  sns_topic_arn  = module.sns.topic_arn
}

module "ecs_cluster" {
  source       = "./modules/ecs_cluster"
  cluster_name = "hotel-reservation-cluster"
}

module "app_service" {
  source = "./modules/app_service"

  task_family         = "hotel-app"
  image               = module.ecr.repository_url
  cpu                 = "256"
  memory              = "512"
  execution_role_arn  = module.iam.execution_role_arn
  task_role_arn       = module.iam.task_role_arn
  cluster_arn         = module.ecs_cluster.cluster_arn
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_id   = module.vpc.app_sg_id
  service_name        = "hotel-reservation-service"
  log_group_name      = "/ecs/hotel-app"
  region              = var.region
  target_group_arn = module.alb.target_group_arn
  sns_topic_arn = module.sns.topic_arn
}

module "alb" {
  source = "./modules/alb"
  name   = "hotel-app-alb"

  subnet_ids         = module.vpc.public_subnet_ids
  vpc_id             = module.vpc.vpc_id
  security_group_id  = module.vpc.app_sg_id
}

module "sns" {
  source     = "./modules/sns"
  topic_name = "hotel-booking-events"
}

module "sqs_payment" {
  source     = "./modules/sqs"

  queue_name = "hotel-payment-queue"
  topic_arn  = module.sns.topic_arn
}

module "ecr" {
  source = "./modules/ecr"
  name   = "hotel-app"
}