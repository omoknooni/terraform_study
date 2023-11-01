resource "aws_cloudfront_distribution" "cf-webdemo-distribution" {
    origin {
      domain_name = aws_s3_bucket.cf_webdemo_bucket.bucket_domain_name
      origin_id = "cf-webdemo"
    }
    enabled = true
    is_ipv6_enabled = false
    comment = "cf-webdemo"
    default_root_object = "index.html"
    

    # cache 동작 설정
    default_cache_behavior {
        allowed_methods = [ "GET", "HEAD", "POST", "PUT", "DELETE", "PATCH", "OPTIONS" ]
        cached_methods = [ "GET", "HEAD" ]
        target_origin_id = aws_s3_bucket.cf_webdemo_bucket.id
        viewer_protocol_policy = "redirect-to-https"
    }
    
    # 국가 제한 설정
    restrictions {
        geo_restriction {
            restriction_type = none
        }
    }

    # SSL 인증서 관련 설정
    # cloudfront_default_certificate -> cloudfront에서 제공하는 기본값
    # acm_certificate_id -> acm에서 생성한 ssl 인증서 id 
    viewer_certificate {
        cloudfront_default_certificate = true
    }


}