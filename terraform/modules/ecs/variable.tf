variable "db_secret_arn" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}


variable "redis_url" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "api_blue_tg_arn" {
  type = string
}

variable "dashboard_blue_tg_arn" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}

variable "image_tag" {
  type        = string
}

variable "api_repo_url" {
  type = string
}
variable "worker_repo_url" {
  type = string
}
variable "dashboard_repo_url" {
  type = string
}