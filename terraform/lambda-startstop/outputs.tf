output "function_name" {
  description = "The name of the Lambda function"
  value       = "${aws_lambda_function.lambda.function_name}"
}
