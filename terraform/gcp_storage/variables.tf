variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "bucket_name" {
  description = "Имя GCS-бакета (must be globally unique)"
  type        = string
  validation {
    condition     = length(var.bucket_name) > 3 && length(var.bucket_name) < 63
    error_message = "Имя бакета должно быть длиной от 3 до 63 символов."
  }
}

variable "credentials_file" {
  description = "Путь к файлу credentials.json"
  default     = "~/.config/gcloud/application_default_credentials.json"
  type        = string
}

variable "location" {
  description = "Регион создания бакета"
  type        = string
  default     = "us-central1"
}

variable "versioning_enabled" {
  description = "Включить версионирование объектов"
  type        = bool
  default     = true
}

variable "lifecycle_days" {
  description = "Сколько дней хранить старые версии до удаления"
  type        = number
  default     = 30
  validation {
    condition     = var.lifecycle_days >= 1
    error_message = "Количество дней должно быть положительным числом."
  }
}
