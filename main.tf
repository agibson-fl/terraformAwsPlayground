locals {
  bucket_name = "agibson-test-bucket2"
  s3_origin_id = "S3-${aws_s3_bucket.static_site.bucket}"
}


resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "${local.bucket_name}-origin-access-identity"
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["arn:aws:s3:::${local.bucket_name}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}


#---------------------------------------------------------------
# S3 bucket
#---------------------------------------------------------------

resource "aws_s3_bucket" "static_site" {
  bucket = "${local.bucket_name}"
  acl = "private"
  policy = "${data.aws_iam_policy_document.s3_policy.json}"
  region = "us-east-1"

  website {
    index_document = "index.html"
  }
}

#Neat, I can upload the file right from here...
resource "aws_s3_bucket_object" "index" {
  bucket = "${aws_s3_bucket.static_site.bucket}"
  content_type = "text/html"
  key    = "index.html"
  source = "./index.html"

  # The filemd5() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the md5() function and the file() function:
  # etag = "${md5(file("path/to/file"))}"
  etag = "${filemd5("./index.html")}"
}


#---------------------------------------------------------------
#Cloudfront to redirect to https
#---------------------------------------------------------------
resource "aws_cloudfront_distribution" "cf" {
  enabled             = "true"
  default_root_object = "index.html"
  
  origin {
    domain_name = "${aws_s3_bucket.static_site.bucket_domain_name}"
    origin_id   = "${local.s3_origin_id}"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "${local.s3_origin_id}"
    
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}