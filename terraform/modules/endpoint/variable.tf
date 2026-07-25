variable "vpc_id" {
  type = string
}

variable "private_rt" {
  type = string
}
variable "vpc_cidr" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}