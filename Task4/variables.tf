variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
}

variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "zone" {
  description = "Yandex Cloud zone"
  type        = string
  default     = "ru-central1-a"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "vm_image_id" {
  description = "ID of the VM image to use"
  type        = string
  default     = "fd8emvfmfoaordspe1jr" # Ubuntu 22.04 LTS
}

variable "kafka_version" {
  description = "Kafka version"
  type        = string
  default     = "3.9"
}

variable "postgresql_version" {
  description = "PostgreSQL version"
  type        = string
  default     = "15"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.10.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.10.0.0/24"
}
