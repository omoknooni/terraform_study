# 1) Cognito User Pool & Client
resource "aws_cognito_user_pool" "pool" {
  name = "example-user-pool"
}

resource "aws_cognito_user_pool_client" "pool" {
  name               = "example-app-client"
  user_pool_id       = aws_cognito_user_pool.pool.id
  generate_secret    = false
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

resource "aws_cognito_user" "testuser" {
  user_pool_id = aws_cognito_user_pool.pool.id
  username = var.testuser-name
  password = var.testuser-password
}