output "api_gateway_url" {
  value = aws_api_gateway_deployment.api_deployment.invoke_url
}

output "api_key" {
  value     = aws_api_gateway_api_key.cost_api_key.value
  sensitive = true
}
