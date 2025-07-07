module "vpc" {
  source = "./modules/vpc"

  cidr_block           = var.cidr_block
  availability_zones   = var.availability_zones
  region               = var.region
}

module "sns" {
  source     = "./modules/sns"
  topic_name = "hotel-booking-events"
}

module "dynamodb_reservations" {
  source     = "./modules/dynamodb_reservations"
  table_name = "hotel-reservations"
}

module "iam" {
  source                     = "./modules/iam"
  sns_topic_arn              = module.sns.topic_arn
  dynamodb_reservations_arn  = module.dynamodb_reservations.table_arn
  table_kms_key_arn = module.dynamodb_reservations.table_kms_key_arn
  region = var.region
  account_id = var.account_id
}

module "ecs_cluster" {
  source       = "./modules/ecs_cluster"
  cluster_name = "hotel-reservation-cluster"
}

module "alb" {
  source = "./modules/alb"
  name   = "hotel-app-alb"

  subnet_ids        = module.vpc.public_subnet_ids
  vpc_id            = module.vpc.vpc_id
  security_group_id = module.vpc.alb_sg_id
}

module "ecr" {
  source = "./modules/ecr"
  name   = "hotel-reservation-platform"
}

module "app_service" {
  source                = "./modules/app_service"
  task_family           = "hotel-app"
  image                 = module.ecr.repository_url
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = module.iam.execution_role_arn
  task_role_arn         = module.iam.task_role_arn
  cluster_arn           = module.ecs_cluster.cluster_arn
  subnet_ids            = module.vpc.private_subnet_ids
  security_group_id     = module.vpc.app_sg_id
  service_name          = "hotel-reservation-service"
  log_group_name        = "/ecs/hotel-app"
  desired_count         = 2
  assign_public_ip      = false
  region                = var.region
  target_group_arn      = module.alb.target_group_arn
  sns_topic_arn         = module.sns.topic_arn
  dynamodb_reservations_table_name = module.dynamodb_reservations.table_name
}

locals {
  queues = {
    payment     = "hotel-payment-queue"
    email       = "hotel-email-queue"
    updater     = "hotel-updater-queue"
    analytics   = "hotel-analytics-queue"
  }

  event_filter_policy = {
    payment = ["ReservationCreated", "ReservationUpdated", "ReservationCancelled"]
    email   = ["ReservationCreated", "ReservationUpdated", "ReservationCancelled"]
    updater = ["ReservationUpdated", "ReservationCancelled"]
    analytics = ["ReservationCreated", "ReservationUpdated", "ReservationCancelled"]
  }

  lambda_consumers = {
    email = {
      handler_file = "email_handler.handler"
      zip_path     = "../lambdas/email/email_handler.zip"
      policy_arns  = []
    }
    payment = {
      handler_file = "payment_handler.handler"
      zip_path     = "../lambdas/payment/payment_handler.zip"
      policy_arns  = [module.iam.dynamodb_access_policy_arn, module.iam.kms_dynamodb_access]
    }
    updater = {
      handler_file = "updater_handler.handler"
      zip_path     = "../lambdas/updater/updater_handler.zip"
      policy_arns  = [module.iam.dynamodb_access_policy_arn]
    }
    analytics = {
      handler_file = "analytics_handler.handler"
      zip_path     = "../lambdas/analytics/analytics_handler.zip"
      policy_arns  = []
    }
  }
}

module "sqs_queues" {
  source   = "./modules/sqs"
  for_each = local.queues

  queue_name = each.value
  topic_arn  = module.sns.topic_arn
  event_triggers = local.event_filter_policy[each.key]
}

module "lambda_consumer_iam_roles" {
  source   = "./modules/lambda_consumer_iam_roles"
  for_each = local.lambda_consumers

  name               = each.key
  queue_arn          = module.sqs_queues[each.key].queue_arn
  custom_policy_arns = each.value.policy_arns
  region             = var.region
}

module "lambda_consumers" {
  source           = "./modules/lambda_consumer"
  for_each         = local.lambda_consumers

  name             = each.key
  queue_arn        = module.sqs_queues[each.key].queue_arn
  queue_name       = module.sqs_queues[each.key].queue_name
  lambda_zip_path  = each.value.zip_path
  handler          = each.value.handler_file
  role_arn         = module.lambda_consumer_iam_roles[each.key].role_arn

  environment = {
    DDB_TABLE_NAME = module.dynamodb_reservations.table_name
  }
}
