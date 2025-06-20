resource "aws_ecs_task_definition" "app" {
  family                   = var.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name      = "web-app"
      image     = var.image
      essential = true

      environment = [
        {
          name  = "SNS_TOPIC_ARN"
          value = var.sns_topic_arn
        },
        {
          name  = "AWS_REGION"
          value = var.region
        },
        {
          name  = "DDB_TABLE_NAME"
          value = var.dynamodb_reservations_table_name
        }
      ]

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  depends_on = [aws_cloudwatch_log_group.ecs_app]
}

resource "aws_ecs_service" "app" {
  name            = var.service_name
  cluster         = var.cluster_arn
  task_definition = aws_ecs_task_definition.app.arn
  launch_type     = "FARGATE"
  desired_count   = var.desired_count

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [var.security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "web-app"
    container_port   = 80
  }

  enable_execute_command            = true
  propagate_tags                    = "SERVICE"
  health_check_grace_period_seconds = 60

  depends_on = [aws_ecs_task_definition.app]
}

resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = var.log_group_name
  retention_in_days = 7

  tags = {
    Name = "ECS App Log Group"
  }
}