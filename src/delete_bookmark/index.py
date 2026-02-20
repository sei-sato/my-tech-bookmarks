import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    try:
        # パスパラメータから bookmarkId を取得
        # (例: /bookmarks/{bookmarkId})
        bookmark_id = event['pathParameters']['bookmarkId']
        
        # 削除実行（userIdは現在 'guest' 固定）
        table.delete_item(
            Key={
                'userId': 'guest',
                'bookmarkId': bookmark_id
            }
        )

        return {
            'statusCode': 200,
            'headers': {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            'body': json.dumps({"message": "Successfully deleted"})
        }
    except Exception as e:
        print(e)
        return {
            'statusCode': 500,
            'headers': { "Access-Control-Allow-Origin": "*" },
            'body': json.dumps({"error": str(e)})
        }