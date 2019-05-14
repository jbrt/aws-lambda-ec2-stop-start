variable "function_name" {
  description = "A unique name for your Lambda function (and related IAM resources)"
  type        = "string"
}

variable "handler" {
  description = "The function entrypoint in your code"
  type        = "string"
}

variable "memory_size" {
  description = "Amount of memory in MB your Lambda function can use at runtime"
  type        = "string"
  default     = 128
}

variable "timeout" {
  description = "The amount of time your Lambda function had to run in seconds"
  type        = "string"
  default     = 10
}

variable "description" {
  description = "Description of what your Lambda function does"
  type        = "string"
  default     = "Managed by Terraform"
}

variable "environment" {
  description = "Environment configuration for the Lambda function"
  type        = "map"
  default     = {}
}

variable "tags" {
  description = "A mapping of tags"
  type        = "map"
  default     = {}
}

variable "iam_role_name" {
    description = "The name of the IAM role to use for the function"
    type        = "string"
}

variable "iam_policy_name" {
    description = "The name of the IAM role to use for the function"
    type        = "string"
}

variable "iam_policy_attachment" {
    description = "The name of the IAM role to use for the function"
    type        = "string"
}

