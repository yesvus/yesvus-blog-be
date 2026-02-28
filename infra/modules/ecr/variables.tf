variable "name" {
  type = string
}

variable "keep_image_count" {
  type    = number
  default = 30
}

variable "tags" {
  type    = map(string)
  default = {}
}
