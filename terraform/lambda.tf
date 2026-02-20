# --- ソースコードを自動でzip化 ---
data "archive_file" "create_bookmark_zip" {
  type        = "zip"
  source_dir  = "../src/create_bookmark"
  output_path = "lambda_create_bookmark.zip"
}

data "archive_file" "get_bookmarks_zip" {
  type        = "zip"
  source_dir  = "../src/get_bookmarks"
  output_path = "get_bookmarks.zip"
}

data "archive_file" "delete_bookmark_zip" {
  type        = "zip"
  source_dir  = "../src/delete_bookmark"
  output_path = "delete_bookmark.zip"
}

data "archive_file" "update_bookmark_zip" {
  type        = "zip"
  source_dir  = "../src/update_bookmark"
  output_path = "update_bookmark.zip"
}

resource "archive_file" "bs4_layer_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_layers"
  output_path = "${path.module}/bs4_layer.zip"
}

# --- Lambda実行用ロール (IAM) ---
resource "aws_iam_role" "lambda_role" {
  name = "bookmark_app_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# --- ロールにDynamoDB操作とログ出力の権限を付与 ---
resource "aws_iam_role_policy" "lambda_policy" {
  name = "bookmark_app_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:DeleteItem", "dynamodb:UpdateItem", "dynamodb:Query", "dynamodb:Scan"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.bookmarks.arn # 前に作ったテーブルのARNを参照
      },
      {
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# --- Lambda関数本体の定義 ---
# 登録用Lambda
resource "aws_lambda_function" "create_bookmark" {
  filename         = data.archive_file.create_bookmark_zip.output_path
  function_name    = "CreateBookmarkFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" # index.py の handler 関数を呼ぶという意味
  runtime          = "python3.12"
  timeout          = 10 
  source_code_hash = data.archive_file.create_bookmark_zip.output_base64sha256
  layers = [aws_lambda_layer_version.bs4_layer.arn]

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.bookmarks.name
    }
  }
}

# 取得用Lambda
resource "aws_lambda_function" "get_bookmarks" {
  filename      = data.archive_file.get_bookmarks_zip.output_path
  function_name = "GetBookmarksFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.bookmarks.name
    }
  }
}

# 削除用Lambda
resource "aws_lambda_function" "delete_bookmark" {
  filename      = data.archive_file.delete_bookmark_zip.output_path
  function_name = "DeleteBookmarkFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.bookmarks.name
      }
  }
}

# 更新用Lambda
resource "aws_lambda_function" "update_bookmark" {
  filename      = data.archive_file.update_bookmark_zip.output_path
  function_name = "UpdateBookmarkFunction"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.12"
  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.bookmarks.name
      }
  }
}

# Layerを登録
resource "aws_lambda_layer_version" "bs4_layer" {
  filename            = archive_file.bs4_layer_zip.output_path
  layer_name          = "beautifulsoup4_layer"
  compatible_runtimes = ["python3.12"]
}