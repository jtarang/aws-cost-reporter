# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = var.lambda_role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# Attach Policies to allow AWS Cost Explorer & Tagging API
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.lambda_function_name}-cost-policy"
  description = "Policy for Lambda to access AWS Cost Explorer & tagging API"
  tags = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:GetCostAndUsage",
          "tag:GetResources",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "cost_lambda" {
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_handler
  runtime       = var.lambda_runtime
  filename      = var.lambda_file_path
  timeout       = var.lambda_timeout
  memory_size   = var.lambda_memory_size
  tags = var.tags

  environment {
    variables = {
      SLACK_WEBHOOK_URL    = var.slack_webhook_url
      AWS_COST_TARGET_TAG  = var.cost_target_tag
      AWS_COST_TARGET_KEY  = var.cost_target_key
    }
  }
}

# EventBridge (Cron Job) - Runs daily at 9 AM CST
resource "aws_cloudwatch_event_rule" "daily_cost_report" {
  name                = "${var.lambda_function_name}-daily-cost-report"
  description         = "Runs the cost report Lambda every day at ${var.eventbridge_schedule}"
  schedule_expression = var.eventbridge_schedule
  tags = var.tags
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily_cost_report.name
  target_id = "cost_lambda"
  arn       = aws_lambda_function.cost_lambda.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_cost_report.arn
}

# API Gateway with Lambda Prefix
resource "aws_api_gateway_rest_api" "cost_api" {
  name        = "${var.lambda_function_name}-api"
  description = "API for ${var.lambda_function_name} cost report generation"
  tags = var.tags
}

resource "aws_api_gateway_resource" "cost_resource" {
  rest_api_id = aws_api_gateway_rest_api.cost_api.id
  parent_id   = aws_api_gateway_rest_api.cost_api.root_resource_id
  path_part   = "report"
}

resource "aws_api_gateway_method" "cost_post" {
  rest_api_id   = aws_api_gateway_rest_api.cost_api.id
  resource_id   = aws_api_gateway_resource.cost_resource.id
  http_method   = "POST"
  authorization = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cost_api.id
  resource_id             = aws_api_gateway_resource.cost_resource.id
  http_method             = aws_api_gateway_method.cost_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.cost_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.cost_api.id
}

# API Key for security
resource "aws_api_gateway_api_key" "cost_api_key" {
  name = "${var.lambda_function_name}-api-key"
  tags = var.tags
}

resource "aws_api_gateway_stage" "cost_api_stage" {
  stage_name    = var.api_gateway_stage_name
  rest_api_id   = aws_api_gateway_rest_api.cost_api.id
  deployment_id = aws_api_gateway_deployment.api_deployment.id
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "${var.lambda_function_name}-usage-plan"
  tags = var.tags

  api_stages {
    api_id = aws_api_gateway_rest_api.cost_api.id
    stage  = aws_api_gateway_stage.cost_api_stage.stage_name
  }

  throttle_settings {
    rate_limit  = var.api_rate_limit
    burst_limit = var.api_burst_limit
  }
}

resource "aws_api_gateway_usage_plan_key" "api_key_usage" {
  key_id        = aws_api_gateway_api_key.cost_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.usage_plan.id
}

# Lambda API Gateway Permission
resource "aws_lambda_permission" "api_lambda_permission" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cost_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cost_api.execution_arn}/*/*"
}