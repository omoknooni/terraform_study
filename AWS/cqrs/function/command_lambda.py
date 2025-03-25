import json
import boto3
import uuid
import os
from datetime import datetime

TABLE_NAME = os.environ["TABLE_NAME"]
QUEUE_URL = os.environ["QUEUE_URL"]

dynamodb = boto3.resource('dynamodb')
sqs = boto3.client('sqs')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    item_id = str(uuid.uuid4())  # Unique ID 생성
    timestamp = datetime.utcnow().isoformat()

    # 데이터 저장 (쓰기 모델)
    table = dynamodb.Table(TABLE_NAME)
    table.put_item(
        Item={
            'id': item_id,
            'data': body['data'],
            'timestamp': timestamp
        }
    )

    # 이벤트 메시지 SQS 전송
    message = {
        'id': item_id,
        'data': body['data'],
        'timestamp': timestamp
    }
    sqs.send_message(QueueUrl=QUEUE_URL, MessageBody=json.dumps(message))

    msg = {'message': 'Data written successfully', 'id': item_id}
    print(msg)
    return {
        'statusCode': 200,
        'body': json.dumps(msg)
    }
