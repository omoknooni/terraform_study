import json
import boto3
import os

TABLE_NAME = os.environ["TABLE_NAME"]

dynamodb = boto3.resource('dynamodb')

def lambda_handler(event, context):
    table = dynamodb.Table(TABLE_NAME)
    
    for record in event['Records']:
        message = json.loads(record['body'])
        item_id = message['id']
        data = message['data']
        timestamp = message['timestamp']

        # 읽기 모델 업데이트 (DynamoDB)
        item = {
            'id': item_id,
            'data': data,
            'timestamp': timestamp
        }
        table.put_item(
            Item=item
        )
        print(item)

    msg = {'statusCode': 200, 'body': 'Read model updated'}
    print(msg)
    return msg
