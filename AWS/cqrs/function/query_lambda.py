import json
import boto3
import os

# 환경 변수에서 읽기 모델 테이블 이름 가져오기
TABLE_NAME = os.environ['TABLE_NAME']

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    # API Gateway에서 경로 매개변수로 전달된 id 가져오기
    item_id = event['pathParameters']['id']

    table = dynamodb.Table(TABLE_NAME)
    response = table.get_item(Key={'id': item_id})

    if 'Item' not in response:
        print("Item not found")
        return {
            'statusCode': 404,
            'body': json.dumps({'message': 'Item not found'})
        }

    item = response['Item']
    print(item)
    return {
        'statusCode': 200,
        'body': json.dumps(item)
    }
