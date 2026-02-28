variable "name" {
  type = string
}

variable "bucket_name" {
  type = string
}

variable "enable_versioning" {
  type    = bool
  default = false
}

variable "cors_allowed_origins" {
  type    = list(string)
  default = ["*"]
}

variable "cloudfront_price_class" {
  type    = string
  default = "PriceClass_100"
}

variable "tags" {
  type    = map(string)
  default = {}
}
