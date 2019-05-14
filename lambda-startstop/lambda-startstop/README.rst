Stop/Start Development environment
==================================

How it's works ?
----------------

This solution use two lambda functions (one for starting, one for stopping). 
These functions will targeting the instances based on the tags applyied on them.

You can tell to the functions which tags to use by specifying it in the
environment variables of each function.

You can set these environment variables directly in the Terraform template.
Only one thing is mandatory: you must use the syntax bellow.

- Target<DIGIT> as key
- <TAG>:<VALUE> as value

Here is few examples:

- "Target1" as key and "Project:SmarterEFF" as value
- "Target2" as key and "Environment:Production" as value
- and so on


How to deploy it ?
------------------

You can use the Terraform called "deployment.tf" for doing that.
By default, the functions will be named (but these names are variabilized and 
can be changed):

- ${var.APP_NAME}-${var.BR_NAME}-start
- ${var.APP_NAME}-${var.BR_NAME}-stop

But you can modify that directly in the template.

How to triggered the lambda function ?
--------------------------------------

These functions can be triggered exactly like all other lambda function.
By CLI, for instance :

- aws lambda invoke --function-name <FUNCTION_NAME> --region eu-west-1 output.txt
- aws lambda invoke --function-name <FUNCTION_NAME> --region eu-west-1 output.txt

Note that you will need to install on your PC the AWS CLI (and Python as 
dependency) and set your AWS credentials correctly.

But many other ways to call these functions are possible:
- by CloudWatch Event/Rule
- by API Gateway
- by SNS/SQS 
- ...

How to install a "START/STOP" like button ?
-------------------------------------------

Let's assume that you whant to do that on a Windows machine (but it's nearly
the same thing on a Linux machine). 

Here is the steps:

1. Install Python on the related machine (you may have admin rights to do that)
2. Install the AWS CLI by lauchning this command in cmd.exe : pip install awscli
3. Still in cmd.exe, add your credentials by typing: aws configure

Now you can create two files, like START.bat and STOP.bat and put inside the
corresponding command.

aws lambda invoke --function-name <FUNCTION_NAME> --region <REGION> output.txt

On the AWS IAM side, the user you will use to launch these functions must have
the righs to do that. You can achieve that with this IAM policy:

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Stmt1536831409355",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}

IMPORTANT : the previous example, authorize the user to invoke all the 
functions. You can change that and put the related ARN in
the resource section of the document. 
