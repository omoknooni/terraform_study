# Lambda 실행 역할
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_bucket_policy" {
  name = "lambda_bucket_policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_bucket" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_bucket_policy.arn
}

# Lambda 함수 - 기본/인증 확인용
resource "aws_lambda_function" "hello" {
  function_name    = "api_handler"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = "lambda_function.zip"
  timeout          = 10
  source_code_hash = data.archive_file.hello.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = replace(var.bucket_arn, "arn:aws:s3:::", "")
    }
  }
}

data "archive_file" "hello" {
  type = "zip"
  source_file = "${path.module}/../lambda_function.py"
  output_path = "${path.module}/lambda_function.zip"
}

# API Gateway → Lambda 호출 권한
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.mygw.execution_arn}/*/*"
}

# Lambda에서 Cognito InitiateAuth를 호출할 수 있는 IAM 정책
resource "aws_iam_policy" "lambda_cognito_policy" {
  name        = "lambda-cognito-initiateauth"
  description = "Allow Lambda to call Cognito InitiateAuth"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "cognito-idp:InitiateAuth",
        "cognito-idp:AdminInitiateAuth"
      ],
      "Effect": "Allow",
      "Resource": "${aws_cognito_user_pool.pool.arn}"
    }
  ]
}
EOF
}

# Lambda 실행 역할에 정책 붙이기
resource "aws_iam_role_policy_attachment" "lambda_cognito_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_cognito_policy.arn
}

# Token 발급용 Lambda 함수
resource "aws_lambda_function" "token" {
  function_name    = "cognito_token_issuer"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_token.lambda_handler"
  runtime          = "python3.12"
  filename         = "lambda_token.zip"
  source_code_hash = data.archive_file.token.output_base64sha256
  timeout          = 10
  
  environment {
    variables = {
      COGNITO_USER_POOL_ID = aws_cognito_user_pool.pool.id
      COGNITO_APP_CLIENT_ID = aws_cognito_user_pool_client.pool.id
    }
  }
}

data "archive_file" "token" {
  type = "zip"
  source_file = "${path.module}/../lambda_token.py"
  output_path = "${path.module}/lambda_token.zip"
}

# API Gateway → Token Lambda 호출 권한
resource "aws_lambda_permission" "apigw_token" {
  statement_id  = "AllowAPIGatewayInvokeToken"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.token.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.mygw.execution_arn}/*/POST/token"
}