provider "aws" {
  region  = var.REGION
  version = "2.12.0"
  profile = "default"
}

# WARNING: we still used the 0.11 version of Terraform
terraform {
  # required_version = "<= 0.11.13"
}

# INPUT variables you should add your own or and new ones

variable "REGION" {
  default = "eu-west-1"
}

# Here we declare the variables passing through the CLI
variable "ENV_NAME" {
  default = "DEV"
}

variable "APP_NAME" {
  default = "MyNewApp"
}

# IMPORTANT: 
# Use this map to define the environment variables for the lambda 
# functions. This variables will be used TO TARGET instances in order to
# stop/start them.

locals {
  environment_variables = {
    Target1 = "Environment:${var.ENV_NAME}"
    Target2 = "Product:${var.APP_NAME}"
  }

  # The "tags" variable is only to set tags on lambda function for better
  # tracking
  tags = {
    Project     = var.APP_NAME
    Environment = var.ENV_NAME
  }
}

# Log Groups
resource "aws_cloudwatch_log_group" "log_group_stop" {
  name              = "/aws/lambda/${var.APP_NAME}-${var.ENV_NAME}-stop"
  retention_in_days = "7"
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "log_group_start" {
  name              = "/aws/lambda/${var.APP_NAME}-${var.ENV_NAME}-start"
  retention_in_days = "7"
  tags              = local.tags
}

# Declare a function to STOP instances with the right tags
module "function_stop" {
  source                = "./lambda-startstop"
  function_name         = "${var.APP_NAME}-${var.ENV_NAME}-stop"
  description           = "This lambda will stop the EC2 ${var.ENV_NAME} environnement"
  handler               = "lambda_function.stop_handler"
  memory_size           = 128
  timeout               = 30
  iam_role_name         = "lambda-${var.APP_NAME}-${var.ENV_NAME}-stop"
  iam_policy_name       = "EC2AutoStop${var.APP_NAME}_${var.ENV_NAME}Environment"
  iam_policy_attachment = "attach-${var.APP_NAME}-${var.ENV_NAME}-auto-stop"
  tags                  = local.tags
  environment           = local.environment_variables
}

# Declare a function to START instances with the right tags
module "function_start" {
  source                = "./lambda-startstop"
  function_name         = "${var.APP_NAME}-${var.ENV_NAME}-start"
  description           = "This lambda will start the EC2 ${var.ENV_NAME} environnement"
  handler               = "lambda_function.start_handler"
  memory_size           = 128
  timeout               = 300
  iam_role_name         = "lambda-${var.APP_NAME}-${var.ENV_NAME}-start"
  iam_policy_name       = "EC2AutoStart${var.APP_NAME}_${var.ENV_NAME}Environment"
  iam_policy_attachment = "attach-${var.APP_NAME}-${var.ENV_NAME}-auto-start"
  tags                  = local.tags
  environment           = local.environment_variables
}

# Display the name of the Lambda function
output "lambda_function_for_stopping" {
  value = module.function_stop.function_name
}

output "lambda_function_for_starting" {
  value = module.function_start.function_name
}

