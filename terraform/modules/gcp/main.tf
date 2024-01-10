locals {
  onprem = ["182.1.11.111"] # local ip machine
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket
resource "google_storage_bucket" "data-lake" {
  project                     = var.project_id
  name                        = var.gcs_name
  location                    = var.gcs_location # https://cloud.google.com/storage/docs/locations
  storage_class               = var.gcs_storage_class
  uniform_bucket_level_access = true
  force_destroy               = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/sql_database_instance
resource "google_sql_database_instance" "data-master" {
  project             = var.project_id
  name                = var.cloud_sql_name
  region              = var.region
  database_version    = var.cloud_sql_database_version
  deletion_protection = false

  settings {
    tier = var.cloud_sql_tier

    ip_configuration {
      dynamic "authorized_networks" {
        for_each = local.onprem
        iterator = onprem

        content {
          name  = "onprem-${onprem.key}"
          value = onprem.value
        }
      }
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret
resource "google_secret_manager_secret" "data-cloud-sql-secret" {
  project   = var.project_id
  secret_id = var.secret_manager_cloud_sql_secret_id

  replication {
    auto {

    }
  }
}

resource "google_secret_manager_secret_version" "data-cloud-sql-secret-key" {
  secret = google_secret_manager_secret.data-cloud-sql-secret.id
  secret_data = jsonencode({
    host     = var.secret_manager_cloud_sql_db_host
    port     = var.secret_manager_cloud_sql_db_port
    database = var.secret_manager_cloud_sql_db_name
    user     = var.secret_manager_cloud_sql_db_user
    password = var.secret_manager_cloud_sql_db_password
  })
}


# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/bigquery_dataset
resource "google_bigquery_dataset" "data-warehouse" {
  project                    = var.project_id
  dataset_id                 = var.bigquery_dataset_id
  location                   = var.region # https://cloud.google.com/bigquery/docs/locations
  delete_contents_on_destroy = true
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_cluster
resource "google_dataproc_cluster" "data-cluster" {
  project = var.project_id
  name    = var.dataproc_name
  region  = var.region

  labels = {
    "google-dataproc-cluster-name" : var.dataproc_name
  }

  cluster_config {
    lifecycle_config {
      idle_delete_ttl = "86400s"
    }

    software_config {
      override_properties = {
        "dataproc:dataproc.allow.zero.workers" = "true"
      }
      optional_components = [
        "JUPYTER"
      ]
    }

    endpoint_config {
      enable_http_port_access = "true"
    }

    master_config {
      machine_type = var.dataproc_machine_type
    }
  }
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/dataproc_workflow_template
resource "google_dataproc_workflow_template" "data-pipeline" {
  name       = var.dataproc_template_name
  location   = var.region
  depends_on = [google_dataproc_cluster.data-cluster]

  placement {
    cluster_selector {
      cluster_labels = google_dataproc_cluster.data-cluster.labels
    }
  }

  jobs {
    step_id = "job-cleanup"
    spark_sql_job {
      query_file_uri = "gs://${var.gcs_name}/scripts/daily_product_revenue/cleanup.sql"
    }
  }

  jobs {
    step_id               = "job-convert-orders"
    prerequisite_step_ids = ["job-cleanup"]
    spark_sql_job {
      query_file_uri = "gs://${var.gcs_name}/scripts/daily_product_revenue/file_format_converter.sql"
      script_variables = {
        "bucket_name" : "gs://${var.gcs_name}",
        "table_name" : "orders"
      }
    }
  }

  jobs {
    step_id               = "job-convert-order-items"
    prerequisite_step_ids = ["job-cleanup"]
    spark_sql_job {
      query_file_uri = "gs://${var.gcs_name}/scripts/daily_product_revenue/file_format_converter.sql"
      script_variables = {
        "bucket_name" : "gs://${var.gcs_name}",
        "table_name" : "order_items"
      }
    }
  }

  jobs {
    step_id               = "job-daily-product-revenue"
    prerequisite_step_ids = ["job-convert-orders", "job-convert-order-items"]
    spark_sql_job {
      query_file_uri = "gs://${var.gcs_name}/scripts/daily_product_revenue/compute_daily_product_revenue.sql"
      script_variables = {
        "bucket_name" : "gs://${var.gcs_name}",
      }
    }
  }

  jobs {
    step_id               = "job-load-daily-product-revenue-bigquery"
    prerequisite_step_ids = ["job-daily-product-revenue"]
    pyspark_job {
      main_python_file_uri = "gs://${var.gcs_name}/apps/daily_product_revenue_bq/app.py"
      jar_file_uris = [
        "gs://spark-lib/bigquery/spark-bigquery-with-dependencies_2.12-0.26.0.jar"
      ]
      properties = {
        "spark.name" : "Dataproc to Bigquery ETL",
        "spark.submit.deployMode" : "cluster",
        "spark.yarn.appMasterEnv.DATA_URI" : "gs://${var.gcs_name}/retail_gold.db/daily_product_revenue"
        "spark.yarn.appMasterEnv.PROJECT_ID" : var.project_id,
        "spark.yarn.appMasterEnv.DATASET_NAME" : var.bigquery_dataset_id,
        "spark.yarn.appMasterEnv.GCS_TEMP_BUCKET" : var.gcs_name
      }
    }
  }
}

# granted roles/composer.ServiceAgentV2Ext via Composer UI
data "google_service_account" "terraform-account" {
  project    = var.project_id
  account_id = var.account_id
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/composer_environment
resource "google_composer_environment" "data-orchestration" {
  project = var.project_id
  name    = var.cloud_composer_name
  region  = var.region

  config {
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    software_config {
      image_version = "composer-2-airflow-2"
    }

    node_config {
      service_account = data.google_service_account.terraform-account.name
    }
  }
}
