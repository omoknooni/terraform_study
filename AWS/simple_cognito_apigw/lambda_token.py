import os
import json
import boto3

USER_POOL_ID = os.environ['COGNITO_USER_POOL_ID']
CLIENT_ID    = os.environ['COGNITO_APP_CLIENT_ID']

cognito = boto3.client('cognito-idp')

def lambda_handler(event, context):
    """
    요청 본문에 JSON으로 아래 필드를 담기
      {
        "username": "사용자이름",
        "password": "비밀번호"
      }
    """
    body = json.loads(event.get('body') or '{}')
    username = body.get('username')
    password = body.get('password')

    if not username or not password:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "username and password are required"})
        }

    try:
        resp = cognito.initiate_auth(
            ClientId=CLIENT_ID,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )
        # AccessToken, IdToken, RefreshToken 등
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(resp['AuthenticationResult'])
        }

    except cognito.exceptions.NotAuthorizedException:
        return {
            "statusCode": 401,
            "body": json.dumps({"error": "Invalid credentials"})
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
