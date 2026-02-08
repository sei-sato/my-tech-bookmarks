terraform {
  backend "s3" {
    bucket = "my-tech-bookmarks-tfstate"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}