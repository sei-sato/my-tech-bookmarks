import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    try:
        bookmark_id = event['pathParameters']['bookmarkId']
        body = json.loads(event['body'])
        new_status = body.get('status') # unread, learning, done

        # DynamoDBの特定の項目だけを更新（UpdateItem）
        table.update_item(
            Key={
                'userId': 'guest',
                'bookmarkId': bookmark_id
            },
            UpdateExpression="set #s = :s",
            ExpressionAttributeNames={ "#s": "status" }, # statusは予約語のため別名を使う
            ExpressionAttributeValues={ ":s": new_status }
        )

        return {
            'statusCode': 200,
            'headers': { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
            'body': json.dumps({"status": new_status})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': { "Access-Control-Allow-Origin": "*" },
            'body': json.dumps({"error": str(e)})
        }