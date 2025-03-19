locals {
  cluster_name     = "github-runner"
  runner_image_uri = try(module.ecr.images["github_runner"].image_uri, null)
  nginx_image_uri  = try(module.ecr.images["nginx"].image_uri, null)
  tags = {
    name    = local.cluster_name
    type    = "fargate",
    service = "github self-hosted runner",
  }
}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "~> 5.0"

  depends_on = [aws_iam_policy.ecr_pull_accesses, module.ecr]

  cluster_name = local.cluster_name
  cluster_tags = local.tags

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/${local.cluster_name}"
      }
    }
  }

  fargate_capacity_providers = {
    FARGATE = {
      default_capacity_provider_strategy = {
        weight = 100
      }
    }
  }

  services = {
    unreal_engine = {
      cpu           = 4 * 1024
      memory        = 16 * 1024
      desired_count = 0

      ephemeral_storage = {
        size_in_gib = 70
      }

      subnet_ids       = module.vpc.public_subnets
      assign_public_ip = true

      autoscaling_max_capacity           = 10
      autoscaling_min_capacity           = 0
      deployment_minimum_healthy_percent = 0

      autoscaling_policies = {}

      enable_execute_command = true

      create_task_exec_iam_role          = true
      task_exec_iam_role_use_name_prefix = false
      task_exec_iam_role_name            = "ECSFargateTaskExec"

      create_tasks_iam_role          = true
      tasks_iam_role_use_name_prefix = false
      tasks_iam_role_name            = "ECSFargateTasks"

      create_iam_role          = true
      iam_role_use_name_prefix = false
      iam_role_name            = "ECSFargateService"

      tasks_iam_role_policies = {
        ECRAccesses = aws_iam_policy.ecr_pull_accesses.arn
      }

      create_security_group = true
      security_group_name   = "ecs-${local.cluster_name}"

      security_group_rules = {
        egress_443 = {
          type        = "egress"
          description = "Allow HTTPS traffic to the internet"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"] # ✅ Allows outbound HTTPS to all destinations
        }
        egress_dns_udp = {
          type        = "egress"
          description = "Allow DNS resolution over UDP"
          from_port   = 53
          to_port     = 53
          protocol    = "udp"
          cidr_blocks = ["0.0.0.0/0"]
        }

        egress_dns_tcp = {
          type        = "egress"
          description = "Allow DNS resolution over TCP (for large responses)"
          from_port   = 53
          to_port     = 53
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }

      container_definitions = [
        {
          name                     = "unreal-runner" //TODO: make a parameter
          image                    = local.runner_image_uri
          cpu                      = 4 * 1024 - 256
          memory                   = 16 * 1024 - 512
          essential                = true
          user                     = "1000" //TODO: test with out it
          readonly_root_filesystem = false  //TODO: test with out it

          command = [
            "--repo", var.github_org,
            "--token", jsondecode(data.aws_secretsmanager_secret_version.github_runner_token.secret_string)["Token"],
            "--runner-name", "ue_5.4.4_runner",
            "--labels", "fargate,ue,5.4.4",
            "--ecs-task"
          ]

          # entrypoint = ["bash", "-c", "echo $HTTPS_PROXY .github.com"]

          environment = [
            { name = "HTTPS_PROXY", value = "http://localhost:${local.nginx_conf.port}" },
            { name = "HTTP_PROXY", value = "http://localhost:${local.nginx_conf.port}" },
            { name = "NO_PROXY", value = "localhost,127.0.0.1" } # Avoid looping requests
          ]

          dependencies = [ # Ensure proxy starts first
            {
              containerName = "nginx-proxy"
              condition     = "HEALTHY"
            }
          ]
        },
        {
          name                     = "nginx-proxy"
          image                    = local.nginx_image_uri
          cpu                      = 256
          memory                   = 512
          essential                = true
          readonly_root_filesystem = false

          port_mappings = [
            {
              name          = "proxy"
              containerPort = local.nginx_conf.port
              hostPort      = local.nginx_conf.port
            }
          ]

          health_check = {
            command = [
              "CMD-SHELL",
              "nslookup ${local.nginx_conf.allowed_server_names[0]} && curl -fsSL -x http://localhost:${local.nginx_conf.port} https://api.github.com || exit 1"
            ],
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 60
          }
        }
      ]
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
    Project     = "unreal engine"
  }
}

resource "aws_iam_role_policy_attachment" "tasks-iam-role-ecs-control-attach" {
  depends_on = [module.ecs, aws_iam_policy.ecs_update_service_policy]

  for_each = module.ecs.services

  role       = each.value.tasks_iam_role_name
  policy_arn = aws_iam_policy.ecs_update_service_policy.arn
}
