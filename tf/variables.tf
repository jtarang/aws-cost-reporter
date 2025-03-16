variable "aws_region" {
  description = "AWS region"
}

variable "lambda_function_name" {
  description = "Lambda Function Name"
  type = string
}

variable "lambda_role_name" {
  description = "IAM role for lambda execution"
  type = string
}

variable "lambda_memory_size" {
  description = "Memory size for the Lambda function"
  type        = number
}

variable "lambda_timeout" {
  description = "Timeout for the Lambda function in seconds"
  type        = number
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function"
  type = string
}

variable "lambda_handler" {
  description = "Lambda Handler Function"
}

variable "lambda_file_path" {
  description = "Path to the lambda file/zip"
}

variable "slack_webhook_url" {
  description = "Slack Webhook URL"
  type        = string
}

variable "cost_target_tag" {
  description = "Tag key to filter resources"
  type        = string
}

variable "cost_target_key" {
  description = "Tag value to filter resources"
  type        = string
}

variable "api_gateway_stage_name" {
  description = "The stage name for API Gateway deployment"
  type        = string
}

variable "eventbridge_schedule" {
  description = "Cron expression for EventBridge rule (e.g., daily at 9 AM CST)"
  type        = string
}

variable "api_rate_limit" {
  description = "Rate limit for API Gateway"
  type        = number
}

variable "api_burst_limit" {
  description = "Burst limit for API Gateway"
  type        = number
}

variable "tags" {
  description = "A map of tags to apply to the resources"
  type        = map(string)
}