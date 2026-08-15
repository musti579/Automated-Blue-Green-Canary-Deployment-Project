variable "db_secret_arn" {
  type = string
}

variable "sqs_queue_arn" {
  type = string
}

variable "api_container_image" {
  type = string
}

variable "redis_url" {
  type = string
}

variable "sqs_queue_url" {
  type = string
}

variable "worker_container_image" {
  type = string
}

variable "dashboard_container_image" {
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