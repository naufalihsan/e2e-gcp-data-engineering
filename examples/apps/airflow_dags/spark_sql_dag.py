import datetime

from airflow import models
from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitSparkSqlJobOperator
from airflow.utils.dates import days_ago

project_id = "e2e-pipeline-cs"
region = "asia-southeast2"
dataproc_cluster_name = "e2e-gcp-data-cluster"

default_args = {
    "project_id": project_id,
    "region": region,
    # Tell airflow to start one day ago, so that it runs as soon as you upload it
    "start_date": days_ago(1)
}

with models.DAG(
    "spark_sql_dag",
    default_args=default_args,
    schedule_interval=datetime.timedelta(days=1)
) as dag:
    run_query = DataprocSubmitSparkSqlJobOperator(
        task_id='run_spark_sql_query',
        project_id=project_id,
        region=region,
        cluster_name=dataproc_cluster_name,
        query='SELECT current_date',
    )