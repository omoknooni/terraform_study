import json
import boto3
import os

def lambda_handler(event, context):
    # 인증 정보 확인
    # API Gateway의 Cognito 인증 후 클레임 정보
    claims = event.get('requestContext', {}).get('authorizer', {}).get('claims', {})
    username = claims.get('cognito:username', 'Unknown')
    
    try:
        # 환경변수에서 버킷 이름 가져오기
        bucket_name = os.environ.get('BUCKET_NAME')
        
        if not bucket_name:
            return {
                "statusCode": 400,
                "headers": {"Content-Type": "application/json"},
                "body": json.dumps({"error": "BUCKET_NAME 환경변수가 설정되지 않았습니다."})
            }
        
        # S3 클라이언트 생성
        s3_client = boto3.client('s3')
        
        # 버킷의 객체 목록 가져오기
        response = s3_client.list_objects_v2(Bucket=bucket_name)
        
        # 객체 목록 추출
        objects = []
        if 'Contents' in response:
            for obj in response['Contents']:
                objects.append({
                    'key': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'].isoformat()
                })
        
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({
                "bucket": bucket_name,
                "username": username,
                "objects": objects
            })
        }
    
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"error": str(e)})
        }