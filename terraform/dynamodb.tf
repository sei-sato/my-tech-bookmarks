resource "aws_dynamodb_table" "bookmarks" {
  name           = "MyTechBookmarks"
  billing_mode   = "PAY_PER_REQUEST" # オンデマンド（0円運用の肝）
  hash_key       = "userId"          # パーティションキー
  range_key      = "bookmarkId"      # ソートキー

  attribute {
    name = "userId"
    type = "S" # String
  }

  attribute {
    name = "bookmarkId"
    type = "S" # String
  }

  tags = {
    Name        = "MyTechBookmarks"
  }
}