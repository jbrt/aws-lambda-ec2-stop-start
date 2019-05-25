# Declare the IAM resources

resource "aws_iam_role" "lambda-iam-role" {
  name               = "${var.iam_role_name}"
  assume_role_policy = "${file("${path.module}/files/iam-role.json")}"
}

resource "aws_iam_policy" "lambda-iam-policy" {
  name        = "${var.iam_policy_name}"
  description = "The IAM policy attached to the role"
  policy      = "${file("${path.module}/files/iam-policy.json")}"
}

resource "aws_iam_policy_attachment" "iam-attach" {
  name       = "${var.iam_policy_attachment}"
  roles      = ["${aws_iam_role.lambda-iam-role.name}"]
  policy_arn = "${aws_iam_policy.lambda-iam-policy.arn}"
}

# Build a ZIP file before uploading the lambda_function

data "archive_file" "zipit" {
  type        = "zip"
  source_file = "${path.module}/files/lambda_function.py"
  output_path = "${path.module}/files/lambda_function.zip"
}

# Finally, declare a lambda function

resource "aws_lambda_function" "lambda" {
  function_name    = "${var.function_name}"
  description      = "${var.description}"
  role             = "${aws_iam_role.lambda-iam-role.arn}"
  handler          = "${var.handler}"
  memory_size      = "${var.memory_size}"
  runtime          = "python3.6"
  timeout          = "${var.timeout}"
  tags             = "${var.tags}"
  filename = "${path.module}/files/lambda_function.zip"
  source_code_hash = "${data.archive_file.zipit.output_base64sha256}"
  environment {
    variables = "${var.environment}"
  }
}