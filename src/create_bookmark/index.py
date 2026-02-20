import json
import boto3
import os
import uuid
import datetime
import urllib.request
from bs4 import BeautifulSoup
from decimal import Decimal
import urllib.parse

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["TABLE_NAME"])

# -----------------------------
# OGP取得（タイトル追加版）
# -----------------------------
def get_ogp(url):
    try:
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
            "Accept-Language": "ja,en-US;q=0.9,en;q=0.8",
        }
        req = urllib.request.Request(url, headers=headers)

        with urllib.request.urlopen(req, timeout=5) as res:
            html = res.read().decode("utf-8", errors="ignore")
            soup = BeautifulSoup(html, "html.parser")

            # --- タイトルの取得 ---
            # 1. og:title 2. サイトのtitleタグ 3. URL自体 の優先順位
            title = ""
            title_tag = (
                soup.find("meta", property="og:title") or 
                soup.find("meta", attrs={"name": "twitter:title"})
            )
            if title_tag:
                title = title_tag.get("content", "")
            
            if not title and soup.title:
                title = soup.title.string

            # --- 画像の取得 ---
            image = ""
            img_tag = (
                soup.find("meta", property="og:image") or 
                soup.find("meta", attrs={"name": "twitter:image"}) or
                soup.find("meta", attrs={"name": "og:image"})
            )
            
            if img_tag:
                image = img_tag.get("content", "")
                
            if not image:
                icon_tag = (
                    soup.find("link", rel="icon") or 
                    soup.find("link", rel="shortcut icon") or
                    soup.find("link", rel="apple-touch-icon")
                )
                if icon_tag:
                    image = icon_tag.get("href", "")

            if image and not image.startswith("http"):
                image = urllib.parse.urljoin(url, image)

            # --- 説明文の取得 ---
            description = ""
            desc_tag = (
                soup.find("meta", property="og:description") or 
                soup.find("meta", attrs={"name": "description"}) or
                soup.find("meta", attrs={"name": "twitter:description"})
            )
            
            if desc_tag:
                description = desc_tag.get("content", "")

            return {
                "title": title.strip() if title else "",
                "image": image.strip() if image else "",
                "description": description.strip()[:200] if description else "",
            }

    except Exception as e:
        print(f"OGP取得エラー ({url}): {str(e)}")
        return {"title": "", "image": "", "description": ""}


# -----------------------------
# Lambda handler
# -----------------------------
def handler(event, context):
    try:
        if event.get("httpMethod") == "OPTIONS":
            return {
                "statusCode": 200,
                "headers": cors_headers(),
                "body": json.dumps({"message": "OK"}),
            }

        body = json.loads(event["body"])
        url = body.get("url")
        # タイトルは送られてくるかもしれないし、空かもしれない
        input_title = body.get("title")

        if not url:
            return {
                "statusCode": 400,
                "headers": cors_headers(),
                "body": json.dumps({"message": "url は必須です"}),
            }

        # 高精度OGP取得を実行
        ogp = get_ogp(url)

        # 最終的なタイトルを決定（入力があれば優先、なければ取得したもの、最悪URL）
        final_title = input_title or ogp["title"] or url

        now = datetime.datetime.now()
        timestamp = int(now.timestamp())

        item = {
            "userId": "guest",
            "bookmarkId": str(uuid.uuid4()),
            "url": url,
            "title": final_title,
            "status": "unread",
            "image": ogp["image"],
            "description": ogp["description"],
            "timestamp": timestamp,
            "createdAt": now.isoformat()
        }

        table.put_item(Item=item)

        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps(item, default=str), # Decimalなどの型エラー対策
        }

    except Exception as e:
        print("システムエラー:", str(e))
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"message": "Internal Server Error"}),
        }

def cors_headers():
    return {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token",
        "Access-Control-Allow-Methods": "GET,POST,PATCH,DELETE,OPTIONS",
    }