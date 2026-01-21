variable "waf_name" {
  description = "WAF name (ex: WAF-CJLTEST-PRD)"
  type        = string
}

variable "waf_scope" {
  description = "WAF scope: REGIONAL or CLOUDFRONT"
  type        = string
}

variable "waf_s3_arn" {
  description = "S3 bucket ARN for WAF logging"
  type        = string
}
