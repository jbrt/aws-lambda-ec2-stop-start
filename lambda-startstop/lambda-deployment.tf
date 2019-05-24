provider "aws" {
  region = "eu-west-1"
}

# Here we declare the variables passing through the CLI
variable "BR_NAME" {
  type    = "string"
  default = "DEV"
}

variable "APP_NAME" {
  type    = "string"
  default = "Formation"
}

# IMPORTANT: 
# Use this map to define the environment variables for the lambda 
# functions. This variables will be used TO TARGET instances in order to
# stop/start them.
#
# The "tags" variable is only to set tags on lambda function for better
# tracking
locals {
  environment_variables = {
    Target1 = "Environment:${var.BR_NAME}"
    Target2 = "Product:${var.APP_NAME}"
  }

  tags = {
    Project     = "${var.APP_NAME}"
    Environment = "${var.BR_NAME}"
  }
}

# Declare a function to STOP SmarterEFF Dev environment
module "function_stop" {
  source                = "./lambda-startstop"
  function_name         = "${var.APP_NAME}-${var.BR_NAME}-stop"
  description           = "This lambda will stop the EC2 ${var.BR_NAME} environnement"
  handler               = "lambda_function.stop_handler"
  memory_size           = 128
  timeout               = 30
  iam_role_name         = "lambda-${var.APP_NAME}-${var.BR_NAME}-stop"
  iam_policy_name       = "EC2AutoStop${var.APP_NAME}_${var.BR_NAME}Environment"
  iam_policy_attachment = "attach-${var.APP_NAME}-${var.BR_NAME}-auto-stop"
  tags                  = "${local.tags}"
  environment           = "${local.environment_variables}"
}

# Declare a function to START SmarterEFF Dev environment
module "function_start" {
  source                = "./lambda-startstop"
  function_name         = "${var.APP_NAME}-${var.BR_NAME}-start"
  description           = "This lambda will start the EC2 ${var.BR_NAME} environnement"
  handler               = "lambda_function.start_handler"
  memory_size           = 128
  timeout               = 300
  iam_role_name         = "lambda-${var.APP_NAME}-${var.BR_NAME}-start"
  iam_policy_name       = "EC2AutoStart${var.APP_NAME}_${var.BR_NAME}Environment"
  iam_policy_attachment = "attach-${var.APP_NAME}-${var.BR_NAME}-auto-start"
  tags                  = "${local.tags}"
  environment           = "${local.environment_variables}"
}

output "lambda_function_for_stopping" {
  value = "${module.function_stop.function_name}"
}

output "lambda_function_for_starting" {
  value = "${module.function_start.function_name}"
}
