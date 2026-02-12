import json
import boto3
import os

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def handler(event, context):
    # DynamoDBから全データを取得（Scan）
    # ※ 本来はuserIdでQueryすべきですが、まずはシンプルに全件取得します
    response = table.scan()
    items = response.get('Items', [])

    return {
        'statusCode': 200,
        'headers': {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        # 日時順などでソートして返すと見やすくなります
        'body': json.dumps(items)
    }