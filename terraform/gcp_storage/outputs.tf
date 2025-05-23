output "bucket_name" {
  description = "Имя созданного GCS-бакета"
  value       = google_storage_bucket.main.name
}

output "bucket_self_link" {
  description = "Self Link бакета"
  value       = google_storage_bucket.main.self_link
}

output "bucket_url" {
  description = "URL бакета"
  value       = google_storage_bucket.main.url
}

output "bucket_location" {
  description = "Регион расположения бакета"
  value       = google_storage_bucket.main.location
}

output "bucket_lifecycle_rules" {
  description = "Настроенные правила жизненного цикла бакета"
  value       = google_storage_bucket.main.lifecycle_rule
}
