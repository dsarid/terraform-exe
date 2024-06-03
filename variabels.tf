variable "env" {
  description = "Deployment environment"
  type        = string
  # default     = "dev"
}

variable "resource_alias" {
  description = "my alias name"
  type        = string
  default     = "danielms"
}

variable "region" {
  description = "default region"
  type = string
  default = "eu-central-1"
}

variable "ami_id" {
   description = "EC2 Ubuntu AMI"
   type        = string
}
