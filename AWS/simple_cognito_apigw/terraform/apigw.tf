# API Gateway REST API
resource "aws_api_gateway_rest_api" "mygw" {
  name = "simple-auth"
}

# /hello 리소스와 GET 메소드
resource "aws_api_gateway_resource" "hello" {
  rest_api_id = aws_api_gateway_rest_api.mygw.id
  parent_id   = aws_api_gateway_rest_api.mygw.root_resource_id
  path_part   = "hello"
}

resource "aws_api_gateway_method" "hello_get" {
  rest_api_id   = aws_api_gateway_rest_api.mygw.id
  resource_id   = aws_api_gateway_resource.hello.id
  http_method   = "GET"
  
  # Cognito User Pool을 이용해서 인증하도록 구성 (authorization: NONE -> COGNITO_USER_POOLS)
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito.id
}

# Lambda 통합 (Lambda 프록시 모드)
resource "aws_api_gateway_integration" "hello_get" {
  rest_api_id             = aws_api_gateway_rest_api.mygw.id
  resource_id             = aws_api_gateway_resource.hello.id
  http_method             = aws_api_gateway_method.hello_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hello.invoke_arn
}

# API Gateway 배포
resource "aws_api_gateway_deployment" "mygw" {
  rest_api_id = aws_api_gateway_rest_api.mygw.id
  depends_on = [
    aws_api_gateway_integration.hello_get,
    aws_api_gateway_integration.token_post
  ]
}

resource "aws_api_gateway_stage" "default" {
  rest_api_id = aws_api_gateway_rest_api.mygw.id
  deployment_id = aws_api_gateway_deployment.mygw.id
  stage_name = "dev"
}

# /token 리소스 생성
resource "aws_api_gateway_resource" "token" {
  rest_api_id = aws_api_gateway_rest_api.mygw.id
  parent_id   = aws_api_gateway_rest_api.mygw.root_resource_id
  path_part   = "token"
}

# POST 메소드
resource "aws_api_gateway_method" "token_post" {
  rest_api_id   = aws_api_gateway_rest_api.mygw.id
  resource_id   = aws_api_gateway_resource.token.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda 프록시 통합
resource "aws_api_gateway_integration" "token_post" {
  rest_api_id             = aws_api_gateway_rest_api.mygw.id
  resource_id             = aws_api_gateway_resource.token.id
  http_method             = aws_api_gateway_method.token_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.token.invoke_arn
}

# Cognito Authorizer (인증 관문)
resource "aws_api_gateway_authorizer" "cognito" {
  name                    = "cognito-authorizer"
  rest_api_id             = aws_api_gateway_rest_api.mygw.id
  type                    = "COGNITO_USER_POOLS"
  provider_arns           = [aws_cognito_user_pool.pool.arn]
  identity_source = "method.request.header.Authorization"
}
