variable "name" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.10.0.0/16"
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "private_subnet_cidrs" {
  type = list(string)
}

variable "azs" {
  type = list(string)
}

variable "container_port" {
  type    = number
  default = 8000
}

variable "tags" {
  type    = map(string)
  default = {}
}
