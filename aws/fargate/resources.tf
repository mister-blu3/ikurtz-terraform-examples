// Define the resources to create
// Provisions the following into an existing AWS Account: 
//    Public/Private Subnets, Route Table, NAT Gateway
//    Security Groups, IAM Role, ECS Cluster
//    Cloudwatch Log Group, Cloud Map Namespace and Discovery
//    Task Definitions and Services for Boutique App
//    Load Balancers, Redis Cart and EFS Storage

// Local Variables
locals {
  az_map = zipmap(
    keys(var.subnets),
    slice(data.aws_availability_zones.available.names, 0, length(keys(var.subnets)))
  )
}

// Subnets
resource "aws_subnet" "subnets" {
  for_each = var.subnets

  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = each.value.cidr
  availability_zone       = local.az_map[each.key]
  map_public_ip_on_launch = each.value.type == "public"

  tags = {
    Name        = "${var.name_prefix}-${each.value.type}-subnet-${each.value.name_suffix}"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Route Tables
resource "aws_route_table" "public" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.gw.id
  }

  tags = {
    Name        = "${var.name_prefix}-public-rt"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name        = "${var.name_prefix}-private-rt"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_route_table_association" "rt_assoc" {
  for_each = var.subnets

  subnet_id      = aws_subnet.subnets[each.key].id
  route_table_id = each.value.type == "public" ? aws_route_table.public.id : aws_route_table.private.id
}

// NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.subnets["public_a"].id

  tags = {
    Name        = "${var.name_prefix}-main-nat"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Security Groups
resource "aws_security_group" "lb" {
  name        = "${var.name_prefix}-lb-sg"
  description = "${var.description_prefix} - Security group for load balancer"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-lb-sg"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name_prefix}-app-sg"
  description = "${var.description_prefix} - Security group for ECS tasks"
  vpc_id      = data.aws_vpc.default.id

  # Allow traffic from load balancer security group to port 80
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  # Allow traffic from load balancer security group to port 8080
  ingress {
    from_port       = 80
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.lb.id]
  }

  # Allow all traffic from 10.0.0.0/16
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.name_prefix}-app-sg"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// IAM Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.name_prefix}-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  tags = {
    Name        = "${var.name_prefix}-ecs-task-execution-role"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.name_prefix}-microservices-demo-cluster"

  tags = {
    Name        = "${var.name_prefix}-microservices-demo-cluster"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Cloudwatch Log Group
resource "aws_cloudwatch_log_group" "log_group" {
  for_each = var.microservices

  name              = "/${var.name_prefix}-ecs/${each.key}"
  retention_in_days = 30

  tags = {
    Name        = "${each.key}-log-group"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Cloud Map Namespace and Discovery
resource "aws_service_discovery_private_dns_namespace" "demo" {
  name        = var.cloudmap_namespace
  vpc         = data.aws_vpc.default.id
  description = "${var.description_prefix} - Private DNS namespace for service discovery"

  tags = {
    Name        = "${var.cloudmap_namespace}"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_service_discovery_service" "demo" {
  for_each = var.microservices

  name = each.key

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.demo.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = {
    Name        = each.key
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Task Definitions and Services for Boutique App
resource "aws_ecs_task_definition" "microservice" {
  for_each = var.microservices

  family                   = each.key
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.cpu
  memory                   = each.value.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = each.key
      image     = replace(each.value.image, "{IMAGE_VERSION}", var.demo_app_version)
      essential = true
      portMappings = [
        {
          containerPort = each.value.port
          hostPort      = each.value.port
          name          = "${each.key}-${each.value.port}-${each.value.protocol}"
          appProtocol   = each.value.protocol
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/${var.name_prefix}-ecs/${each.key}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "${var.name_prefix}-ecs"
        }
      }
      environment = [
        for env_var in each.value.env_vars : {
          name  = env_var.name
          value = replace(env_var.value, "{CLOUDMAP_NAMESPACE}", var.cloudmap_namespace)
        }
      ]
      startTimeout = 1800
    }
  ])

  tags = {
    Name        = "${each.key}-task"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_ecs_service" "microservice" {
  for_each = var.microservices

  name            = each.key
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.microservice[each.key].arn
  desired_count   = 1

  launch_type = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnets["public_a"].id, aws_subnet.subnets["public_b"].id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.demo[each.key].arn
  }

  # Only add load balancer configuration for frontend service
  dynamic "load_balancer" {
    for_each = each.key == "frontend" ? [1] : []
    content {
      target_group_arn = aws_lb_target_group.frontend.arn
      container_name   = each.key
      container_port   = each.value.port
    }
  }

  tags = {
    Name        = "${each.key}-service"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Load Balancers
resource "aws_lb" "frontend" {
  name               = "${var.name_prefix}-frontend-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.subnets["public_a"].id, aws_subnet.subnets["public_b"].id]

  tags = {
    Name        = "${var.name_prefix}-frontend-lb"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_lb_target_group" "frontend" {
  name        = "${var.name_prefix}-frontend-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "ip"

  health_check {
    path                = "/_healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.name_prefix}-frontend-tg"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_lb_listener" "frontend" {
  load_balancer_arn = aws_lb.frontend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend.arn
  }

  tags = {
    Name        = "${var.name_prefix}-frontend-listener"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

// Redis Cart and EFS Storage
resource "aws_efs_file_system" "redis_data" {
  creation_token   = "${var.name_prefix}-redis-data"
  performance_mode = "generalPurpose"
  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }
  tags = {
    Name        = "${var.name_prefix}-redis-data"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_efs_mount_target" "redis_data_mt_a" {
  file_system_id  = aws_efs_file_system.redis_data.id
  subnet_id       = aws_subnet.subnets["public_a"].id
  security_groups = [aws_security_group.app.id]
}

resource "aws_efs_mount_target" "redis_data_mt_b" {
  file_system_id  = aws_efs_file_system.redis_data.id
  subnet_id       = aws_subnet.subnets["public_b"].id
  security_groups = [aws_security_group.app.id]
}

resource "aws_cloudwatch_log_group" "redis_log_group" {
  name              = "/${var.name_prefix}-ecs/redis-cart"
  retention_in_days = 30

  tags = {
    Name        = "redis-cart-log-group"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_ecs_task_definition" "redis_task" {
  family                   = "redis-cart"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "redis-cart"
      image     = "redis:alpine"
      cpu       = 0
      essential = true
      portMappings = [
        {
          containerPort = 6379
          hostPort      = 6379
          protocol      = "tcp"
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "${var.name_prefix}-redis-data"
          containerPath = "/data"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/${var.name_prefix}-ecs/redis-cart"
          "awslogs-region"        = var.region
          "awslogs-stream-prefix" = "${var.name_prefix}-ecs"
        }
      }
    }
  ])

  volume {
    name = "${var.name_prefix}-redis-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.redis_data.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    Name        = "redis-cart-task"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_service_discovery_service" "redis_service" {
  name = "redis-cart"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.demo.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }

  tags = {
    Name        = "redis-cart"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}

resource "aws_ecs_service" "redis_service" {
  name            = "redis-cart"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.redis_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnets["public_a"].id, aws_subnet.subnets["public_b"].id]
    security_groups  = [aws_security_group.app.id]
    assign_public_ip = true
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis_service.arn
  }

  tags = {
    Name        = "redis-cart"
    Environment = var.tag_environment
    Project     = var.tag_project
    Owner       = var.tag_owner
  }
}
