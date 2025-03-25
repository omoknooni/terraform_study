# DB for Write
resource "aws_dynamodb_table" "write_table" {
  name         = "CQRSWriteTable"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }
}
# DB for Read
resource "aws_dynamodb_table" "read_table" {
  name           = "CQRSReadTable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# Lambda for WRITE
resource "aws_lambda_function" "command_lambda" {
  function_name    = "CQRS_command"
  runtime         = "python3.12"
  handler         = "command_lambda.lambda_handler"
  role            = aws_iam_role.write_lambda_role.arn
  filename        = "command_lambda.zip"

  environment {
    variables = {
        TABLE_NAME = aws_dynamodb_table.write_table.name
        QUEUE_URL = aws_sqs_queue.event_queue.id
    }
  }
}

data "archive_file" "command_lambda" {
  type = "zip"
  source_file = "./function/command_lambda.py"
  output_path = "command_lambda.zip"
}

# Lambda for READ
resource "aws_lambda_function" "query_lambda" {
  function_name    = "CQRS_query"
  runtime         = "python3.12"
  handler         = "query_lambda.lambda_handler"
  role            = aws_iam_role.read_lambda_role.arn
  filename        = "query_lambda.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.read_table.name
    }
  }
}

data "archive_file" "query_lambda" {
  type = "zip"
  source_file = "./function/query_lambda.py"
  output_path = "query_lambda.zip"
}

# Lambda for Event Processing (Synchronizing Read Table)
resource "aws_lambda_function" "event_processor_lambda" {
  function_name    = "CQRS_EventProcessor"
  runtime          = "python3.12"
  handler          = "event_processor_lambda.lambda_handler"
  role             = aws_iam_role.event_processor_lambda_role.arn
  filename         = "event_processor_lambda.zip"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.read_table.name
    }
  }
}

# Data archive for Event Processor Lambda
data "archive_file" "event_processor_lambda" {
  type        = "zip"
  source_file = "./function/event_processor_lambda.py"
  output_path = "event_processor_lambda.zip"
}

# SQS
resource "aws_sqs_queue" "event_queue" {
  name                      = "cqrs-event-queue"
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.event_queue.arn
  function_name = aws_lambda_function.event_processor_lambda.arn
  batch_size = 10
}


# API GW
resource "aws_api_gateway_rest_api" "cqrs_api" {
  name        = "CQRS_API"
  description = "API Gateway for CQRS"
}

# 리소스 추가 (예: /write)
resource "aws_api_gateway_resource" "write_resource" {
  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
  parent_id   = aws_api_gateway_rest_api.cqrs_api.root_resource_id
  path_part   = "write"
}

# HTTP POST 메서드 추가
resource "aws_api_gateway_method" "write_post" {
  rest_api_id   = aws_api_gateway_rest_api.cqrs_api.id
  resource_id   = aws_api_gateway_resource.write_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

# Lambda 통합 설정
resource "aws_api_gateway_integration" "write_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
  resource_id = aws_api_gateway_resource.write_resource.id
  http_method = aws_api_gateway_method.write_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.command_lambda.invoke_arn
}

# API Gateway 실행 권한을 Lambda에 부여
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.command_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.cqrs_api.execution_arn}/*/*"
}

# Read API Gateway 리소스 생성
resource "aws_api_gateway_resource" "read_resource" {
  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
  parent_id   = aws_api_gateway_rest_api.cqrs_api.root_resource_id
  path_part   = "read"
}

# ID 경로 매개변수 추가 (예: /read/{id})
resource "aws_api_gateway_resource" "read_id_resource" {
  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
  parent_id   = aws_api_gateway_resource.read_resource.id
  path_part   = "{id}"
}

# HTTP GET 메서드 추가
resource "aws_api_gateway_method" "read_get" {
  rest_api_id   = aws_api_gateway_rest_api.cqrs_api.id
  resource_id   = aws_api_gateway_resource.read_id_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda 통합 설정 (AWS_PROXY 사용)
resource "aws_api_gateway_integration" "read_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
  resource_id = aws_api_gateway_resource.read_id_resource.id
  http_method = aws_api_gateway_method.read_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.query_lambda.invoke_arn
}

# API Gateway 배포 (업데이트 포함)
resource "aws_api_gateway_deployment" "cqrs_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.write_lambda_integration,
    aws_api_gateway_integration.read_lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
}

resource "aws_api_gateway_stage" "cqrs_api_stage" {
  deployment_id = aws_api_gateway_deployment.cqrs_api_deployment.id
  rest_api_id = aws_api_gateway_rest_api.cqrs_api.id
  stage_name = "v1"
}

# API Gateway가 Lambda 실행 권한을 갖도록 허용
resource "aws_lambda_permission" "apigw_read_lambda" {
  statement_id  = "AllowAPIGatewayInvokeRead"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.query_lambda.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.cqrs_api.execution_arn}/*/*"
}

# IAM Role
# IAM Role for Write Lambda
resource "aws_iam_role" "write_lambda_role" {
  name = "cqrs_write_lambda_role"

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

# IAM Policy for Write Lambda
resource "aws_iam_role_policy" "write_lambda_policy" {
  name = "cqrs_write_lambda_policy"
  role = aws_iam_role.write_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.write_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.event_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Role for Read Lambda
resource "aws_iam_role" "read_lambda_role" {
  name = "cqrs_read_lambda_role"

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

# IAM Policy for Read Lambda
resource "aws_iam_role_policy" "read_lambda_policy" {
  name = "cqrs_read_lambda_policy"
  role = aws_iam_role.read_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:Query"
        ]
        Resource = aws_dynamodb_table.read_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Role for Event Processor Lambda
resource "aws_iam_role" "event_processor_lambda_role" {
  name = "cqrs_event_processor_lambda_role"

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

# IAM Policy for Event Processor Lambda
resource "aws_iam_role_policy" "event_processor_lambda_policy" {
  name = "cqrs_event_processor_lambda_policy"
  role = aws_iam_role.event_processor_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.event_queue.arn
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.read_table.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}