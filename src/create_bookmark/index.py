import json
import boto3
import os
import uuid
import datetime
import urllib.request
import re
from decimal import Decimal

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])


# -----------------------------
# OGP取得（強化版）
# -----------------------------
def get_ogp(url):
    try:
        headers = {"User-Agent": "Mozilla/5.0"}
        req = urllib.request.Request(url, headers=headers)

        with urllib.request.urlopen(req, timeout=5) as res:
            html = res.read().decode("utf-8", errors="ignore")

            # og:image（順不同対応）
            img_match = re.search(
                r'<meta[^>]+property=["\']og:image["\'][^>]+content=["\'](.*?)["\']',
                html,
                re.IGNORECASE,
            )

            if not img_match:
                img_match = re.search(
                    r'<meta[^>]+content=["\'](.*?)["\'][^>]+property=["\']og:image["\']',
                    html,
                    re.IGNORECASE,
                )

            # og:description（順不同対応）
            desc_match = re.search(
                r'<meta[^>]+property=["\']og:description["\'][^>]+content=["\'](.*?)["\']',
                html,
                re.IGNORECASE,
            )

            if not desc_match:
                desc_match = re.search(
                    r'<meta[^>]+content=["\'](.*?)["\'][^>]+property=["\']og:description["\']',
                    html,
                    re.IGNORECASE,
                )

            # description fallback
            description = ""
            if desc_match:
                description = desc_match.group(1)
            else:
                title_match = re.search(
                    r"<title>(.*?)</title>", html, re.IGNORECASE
                )
                if title_match:
                    description = title_match.group(1)

            image = img_match.group(1) if img_match else ""

            return {
                "image": image,
                "description": description,
            }

    except Exception as e:
        print("OGP取得エラー:", str(e))
        return {"image": "", "description": ""}


# -----------------------------
# Lambda handler
# -----------------------------
def handler(event, context):
    try:
        body = json.loads(event["body"])
        url = body.get("url")
        title = body.get("title")

        if not url or not title:
            return {
                "statusCode": 400,
                "headers": cors_headers(),
                "body": json.dumps({"message": "url と title は必須です"}),
            }

        # OGP取得
        ogp = get_ogp(url)

        item = {
            "userId": "guest",
            "bookmarkId": str(uuid.uuid4()),
            "url": url,
            "title": title,
            "status": "unread",
            "image": ogp["image"],
            "description": ogp["description"],
            'createdAt': datetime.datetime.now().isoformat()
        }

        table.put_item(Item=item)

        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps(item),
        }

    except Exception as e:
        print("エラー:", str(e))
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"message": "Internal Server Error"}),
        }


# -----------------------------
# CORSヘッダー共通化
# -----------------------------
def cors_headers():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    }