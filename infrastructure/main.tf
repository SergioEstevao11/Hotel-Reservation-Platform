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

locals {
  queues = {
    payment     = "hotel-payment-queue"
    email       = "hotel-email-queue"
    fulfillment = "hotel-fulfillment-queue"
    analytics   = "hotel-analytics-queue"
  }
}

module "sqs_queues" {
  source     = "./modules/sqs"
  for_each   = local.queues

  queue_name = each.value
  topic_arn  = module.sns.topic_arn
}

module "ecr" {
  source = "./modules/ecr"
  name   = "hotel-app"
}

locals {
  lambda_consumers = {
    email = {
      handler_file = "email_handler.handler"
      zip_path     = "../lambdas/email_handler.zip"
    }
    payment = {
      handler_file = "payment_handler.handler"
      zip_path     = "../lambdas/payment_handler.zip"
    }
    fulfillment = {
      handler_file = "fulfillment_handler.handler"
      zip_path     = "../lambdas/fulfillment_handler.zip"
    }
    analytics = {
      handler_file = "analytics_handler.handler"
      zip_path     = "../lambdas/analytics_handler.zip"
    }
  }
}

module "lambda_consumers" {
  source           = "./modules/lambda_consumer"
  for_each         = local.lambda_consumers

  name             = each.key
  queue_arn        = module.sqs_queues[each.key].queue_arn
  queue_name       = module.sqs_queues[each.key].queue_name
  lambda_zip_path  = each.value.zip_path
  handler          = each.value.handler_file
}