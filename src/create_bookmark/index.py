import boto3
import uuid
import datetime
import os
import json

# 環境変数からテーブル名を取得（Terraform側で設定します）
TABLE_NAME = os.environ.get('TABLE_NAME')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    body = json.loads(event.get('body', '{}'))
    
    # ユーザーが送ってきたURLを取得（なければデフォルト）
    target_url = body.get('url', 'https://example.com')
    target_title = body.get('title', 'No Title')
    
    bookmark_id = str(uuid.uuid4())
    
    item = {
        'userId': 'test-user-001', 
        'bookmarkId': bookmark_id,
        'url': target_url,
        'title': target_title,
        'status': 'unread',
        'createdAt': datetime.datetime.now().isoformat()
    }
    
    try:
        table.put_item(Item=item)
        return {
            'statusCode': 200,
            'headers': {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps({'message': f"Success: {target_url}"})
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal Server Error'})
        }