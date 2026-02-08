# 1. API Gateway 本体（REST API）
resource "aws_api_gateway_rest_api" "bookmark_api" {
  name        = "BookmarkAPI"
  description = "API for Tech Bookmark App"
}

# 2. リソース（URLのパス /bookmarks）
resource "aws_api_gateway_resource" "bookmarks" {
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id
  parent_id   = aws_api_gateway_rest_api.bookmark_api.root_resource_id
  path_part   = "bookmarks"
}

# 3. メソッド（POST）
resource "aws_api_gateway_method" "post_bookmark" {
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  resource_id   = aws_api_gateway_resource.bookmarks.id
  http_method   = "POST"
  authorization = "NONE" # 開発初期なので認証なし。後でCognitoを繋ぎます。
}

# 4. Lambdaとの統合（APIが呼ばれたらLambdaを起動する）
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.bookmark_api.id
  resource_id             = aws_api_gateway_resource.bookmarks.id
  http_method             = aws_api_gateway_method.post_bookmark.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_bookmark.invoke_arn
}

# 5. API GatewayにLambdaを叩く許可を与える
resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_bookmark.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.bookmark_api.execution_arn}/*/*"
}

# 6. デプロイ（APIの「中身」を固める）
resource "aws_api_gateway_deployment" "bookmark_api_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.bookmark_api.id

  # 毎回デプロイを検知させるためのトリガー（コード変更時に反映されるようにする）
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.bookmarks.id,
      aws_api_gateway_method.post_bookmark.id,
      aws_api_gateway_integration.lambda_integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# 7. ステージ（URLの「場所」を定義する。ここが新推奨！）
resource "aws_api_gateway_stage" "dev" {
  deployment_id = aws_api_gateway_deployment.bookmark_api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.bookmark_api.id
  stage_name    = "dev"
}

# 完了後に表示するURL（参照先を stage に変える）
output "base_url" {
  value = "${aws_api_gateway_stage.dev.invoke_url}/bookmarks"
}