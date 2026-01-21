module "cloudfront_waf" {
  source = "../../modules/waf"

  providers = {
    aws = aws.seoul
  }

  waf_name   = var.waf_name
  waf_scope  = var.waf_scope
  waf_s3_arn = var.waf_s3_arn
}