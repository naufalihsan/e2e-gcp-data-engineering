variable "account_id" {
  default = "terraform"
}

variable "project_id" {
  default = "e2e-pipeline"
}

variable "project_number" {
  default = "111111111111"
}

variable "region" {
  default = "asia-southeast2"
}

variable "zone" {
  default = "asia-southeast2-a"
}

variable "gcs_name" {
  default = "data-lake"
}

variable "gcs_location" {
  default = "ASIA-SOUTHEAST2"
}

variable "gcs_storage_class" {
  default = "STANDARD"
}

variable "cloud_sql_name" {
  default = "data-master"
}

variable "cloud_sql_database_version" {
  default = "POSTGRES_14"
}

variable "cloud_sql_tier" {
  default = "db-f1-micro"
}

variable "secret_manager_cloud_sql_secret_id" {
  default = "cloud-sql-secret"
}

variable "secret_manager_cloud_sql_db_host" {
  default = "127.0.0.1"
}

variable "secret_manager_cloud_sql_db_port" {
  default = "5432"
}

variable "secret_manager_cloud_sql_db_name" {
  default = "postgres"
}

variable "secret_manager_cloud_sql_db_user" {
  default = "postgres"
}

variable "secret_manager_cloud_sql_db_password" {
  default = "postgres"
}

variable "bigquery_dataset_id" {
  default = "data_warehouse"
}

variable "dataproc_name" {
  default = "data-cluster"
}

variable "dataproc_machine_type" {
  default = "n1-standard-4"
}

variable "dataproc_template_name" {
  default = "data-pipeline"
}

variable "cloud_composer_name" {
  default = "data-orchestration"
}
