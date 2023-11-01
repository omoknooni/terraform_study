resource "aws_s3_bucket" "cf_webdemo_bucket" {
    bucket = "cf-webdemo-noonibucket"
}

resource "aws_s3_bucket_acl" "cf_webdemo_bucket_acl" {
    bucket = aws_s3_bucket.cf_webdemo_bucket.id
    acl = "public-read"
}

resource "aws_s3_object" "cf_webdemo_obj" {
    bucket = aws_s3_bucket.cf_webdemo_bucket.id
    key = "index.html"

}

resource "aws_s3_bucket_website_configuration" "cf_webdemo_conf" {
    bucket = aws_s3_bucket.cf_webdemo_bucket.id
    index_document {
      suffix = "index.html"
    }
    error_document {
      key = "error.html"
    }
}