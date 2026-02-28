output "bucket_name" {
  value = aws_s3_bucket.images.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.images.arn
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.images.domain_name
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.images.id
}
