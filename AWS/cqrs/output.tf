output "apigw_url" {
  value = aws_api_gateway_deployment.cqrs_api_deployment.invoke_url
}