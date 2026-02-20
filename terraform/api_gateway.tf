# API Gateway 本体（REST API）
resource "aws_api_gateway_rest_api" "bookmark_api" {
  name        = "BookmarkAPI"
  description = "API for Tech Bookmark App"
}

# リソース（URLのパス /bookmarks）
resource "aws_api_gateway_resource" "bookmarks" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  parent_id   = aws_api_gateway_rest_api.bookmark_api.root_resource_id
  path_part   = "bookmarks"
}

# パスパラメータ {bookmarkId} 用のリソース
resource "aws_api_gateway_resource" "bookmark_item" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  parent_id   = aws_api_gateway_resource.bookmarks.id # /bookmarks の下
  path_part   = "{bookmarkId}"
}

# POSTメソッド
resource "aws_api_gateway_method" "post_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "POST"
  authorization = "NONE" # 開発初期なので認証なし。後でCognitoを繋ぎます。
}

# OPTIONSメソッド(CORS設定) 
resource "aws_api_gateway_method" "options_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# GETメソッド
resource "aws_api_gateway_method" "get_bookmarks" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "GET"
  authorization = "NONE"
}

# DELETEメソッドの定義
resource "aws_api_gateway_method" "delete_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmark_item.id
  http_method   = "DELETE"
  authorization = "NONE"
}

# {bookmarkId} リソース用の OPTIONS メソッド
resource "aws_api_gateway_method" "options_bookmark_item" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmark_item.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# PATCHメソッド
resource "aws_api_gateway_method" "patch_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmark_item.id
  http_method   = "PATCH"
  authorization = "NONE"
}

# Lambdaとの統合（APIが呼ばれたらLambdaを起動する）
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookmark_api.id
  resource_id             = aws_api_gateway_resource.bookmarks.id
  http_method             = aws_api_gateway_method.post_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_bookmark.invoke_arn
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  resource_id = aws_api_gateway_resource.bookmarks.id
  http_method = aws_api_gateway_method.options_bookmark.http_method
  type        = "MOCK" # Lambdaを呼ばず、API Gatewayがその場で即答する
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

# GET用のIntegration
resource "aws_api_gateway_integration" "get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookmark_api.id
  resource_id             = aws_api_gateway_resource.bookmarks.id
  http_method             = aws_api_gateway_method.get_bookmarks.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_bookmarks.invoke_arn
}

# Lambdaとの紐付け（Integration）
resource "aws_api_gateway_integration" "delete_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookmark_api.id
  resource_id             = aws_api_gateway_resource.bookmark_item.id
  http_method             = aws_api_gateway_method.delete_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.delete_bookmark.invoke_arn
}

# PATCH統合
resource "aws_api_gateway_integration" "patch_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookmark_api.id
  resource_id             = aws_api_gateway_resource.bookmark_item.id
  http_method             = aws_api_gateway_method.patch_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_bookmark.invoke_arn # 新しいLambdaを参照
}

# {bookmarkId} リソース用の OPTIONS 統合
resource "aws_api_gateway_integration" "options_bookmark_item_integration" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  resource_id = aws_api_gateway_resource.bookmark_item.id
  http_method = aws_api_gateway_method.options_bookmark_item.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = jsonencode({ statusCode = 200 })
  }
}

# API GatewayにLambdaを叩く許可を与える
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_bookmark.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookmark_api.execution_arn}/*/*"
}

# Lambda起動許可（GET用）
resource "aws_lambda_permission" "apigw_get_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayGet"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_bookmarks.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookmark_api.execution_arn}/*/*"
}

# 削除用Lambdaへの起動許可
resource "aws_lambda_permission" "apigw_delete_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayDelete"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.delete_bookmark.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookmark_api.execution_arn}/*/*"
}

# 更新用Lambdaへの起動許可
resource "aws_lambda_permission" "apigw_update_lambda" {
  statement_id  = "AllowExecutionFromAPIGatewayUpdate"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_bookmark.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookmark_api.execution_arn}/*/*"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  resource_id = aws_api_gateway_resource.bookmarks.id
  http_method = aws_api_gateway_method.options_bookmark.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  resource_id = aws_api_gateway_resource.bookmarks.id
  http_method = aws_api_gateway_method.options_bookmark.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,DELETE,OPTIONS,PATCH'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'" # すべてのサイトからのアクセスを許可
  }

  depends_on = [aws_api_gateway_integration.options_integration]
}

# {bookmarkId} リソース用の OPTIONS レスポンス
resource "aws_api_gateway_method_response" "options_bookmark_item_200" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  resource_id = aws_api_gateway_resource.bookmark_item.id
  http_method = aws_api_gateway_method.options_bookmark_item.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_bookmark_item_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  resource_id = aws_api_gateway_resource.bookmark_item.id
  http_method = aws_api_gateway_method.options_bookmark_item.http_method
  status_code = aws_api_gateway_method_response.options_bookmark_item_200.status_code
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,DELETE,OPTIONS,PATCH'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  depends_on = [aws_api_gateway_integration.options_bookmark_item_integration]
}

# 完了後に表示するURL（参照先を stage に変える）
output "base_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/bookmarks"
}

# デプロイ（APIの「中身」を固める）
resource "aws_api_gateway_deployment" "bookmark_api_deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.options_integration
  ]
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.bookmarks.id,
      aws_api_gateway_resource.bookmark_item.id,
      aws_api_gateway_method.post_bookmark.id,
      aws_api_gateway_method.options_bookmark.id,
      aws_api_gateway_method.get_bookmarks.id,
      aws_api_gateway_method.delete_bookmark.id,
      aws_api_gateway_method.patch_bookmark.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_integration.options_integration.id,
      aws_api_gateway_integration.get_lambda_integration.id,
      aws_api_gateway_integration.delete_integration.id,
      aws_api_gateway_integration.patch_integration.id,
      aws_api_gateway_integration.options_bookmark_item_integration
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ステージ（URLの「場所」を定義する。ここが新推奨！）
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.bookmark_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  stage_name    = "dev"
}