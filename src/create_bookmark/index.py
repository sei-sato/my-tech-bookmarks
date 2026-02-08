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
    # 本来はAPIからデータを受け取りますが、まずは疎通確認用に固定データを入れる
    bookmark_id = str(uuid.uuid4())
    
    item = {
        'userId': 'test-user-001', 
        'bookmarkId': bookmark_id,
        'url': 'https://aws.amazon.com/',
        'title': 'AWS Official Site',
        'status': 'unread',
        'createdAt': datetime.datetime.now().isoformat()
    }
    
    try:
        table.put_item(Item=item)
        return {
            'statusCode': 200,
            'body': json.dumps({'message': f"Success: {bookmark_id}"})
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'Internal Server Error'})
        }