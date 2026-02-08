# --- 1. ソースコードを自動でzip化 ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "../src/create_bookmark"
  output_path = "lambda_create_bookmark.zip"
}

# --- 2. Lambda実行用ロール (IAM) ---
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

# --- 3. ロールにDynamoDB操作とログ出力の権限を付与 ---
resource "aws_iam_role_policy" "lambda_policy" {
  name = "bookmark_app_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:Query"]
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

# --- 4. Lambda関数本体の定義 ---
resource "aws_lambda_function" "create_bookmark" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = "CreateBookmarkFunction"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.handler" # index.py の handler 関数を呼ぶという意味
  runtime          = "python3.12"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.bookmarks.name
    }
  }
}