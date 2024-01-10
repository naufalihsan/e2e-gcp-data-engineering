module "gcp" {
  source = "./modules/gcp"

  # google secret manager tfvars
  secret_manager_cloud_sql_db_host     = var.secret_manager_cloud_sql_db_host
  secret_manager_cloud_sql_db_port     = var.secret_manager_cloud_sql_db_port
  secret_manager_cloud_sql_db_name     = var.secret_manager_cloud_sql_db_name
  secret_manager_cloud_sql_db_user     = var.secret_manager_cloud_sql_db_user
  secret_manager_cloud_sql_db_password = var.secret_manager_cloud_sql_db_password
}
