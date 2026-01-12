aws_region = "us-east-1"

aws_profile_name = ""

# Tagging for resources
tags = {
  "teleport.dev/creator" = "jasmit.tarang@goteleport.com"  # Creator's email
  "Owner"                = "Jasmit Tarang"  # Resource owner
  "Team"                 = "Solutions Engineering"  # Team responsible
  "Environment"          = "Production"
}

lambda_function_name = "jasmit-cost-report-lambda-function"
lambda_role_name = "jasmit-lambda-cost-role"
lambda_handler = "aws_cost_report_lambda.handler"
lambda_memory_size = 128
lambda_timeout = 30
lambda_runtime = "python3.13"

## Slack Webhook URL/ `slack_webhook_url` is a secret
## will be grabbed from env variables

cost_target_tag = "Environment"
cost_target_key = "jasmit-cost-tracker-enabled-true"
api_gateway_stage_name = "prod"
eventbridge_schedule = "cron(0 15 * * ? *)" # 9 AM CST (UTC Time)

api_rate_limit = 10
api_burst_limit = 2
