from datetime import datetime

from airflow import models
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from airflow.providers.dbt.cloud.operators.dbt import DbtCloudRunJobOperator

dbt_account_id = Variable.get("DBT_ACCOUNT_ID")
dbt_job_id = Variable.get("DBT_JOB_COMPUTE_DAILY_REVENUE_ID")

default_args = {
    "dbt_cloud_conn_id": "dbt_cloud",
    "account_id": dbt_account_id,
}

with models.DAG(
    "compute_daily_product_revenue",
    default_args=default_args,
    start_date=datetime(2023, 1, 1),
    schedule_interval=None,
    catchup=False,
) as dag:
    ingest_data = EmptyOperator(task_id="ingest_data")
    notify_user = EmptyOperator(task_id="notify_user")

    transform_daily_product_revenue = DbtCloudRunJobOperator(
        task_id="transform_daily_product_revenue",
        job_id=dbt_job_id,
        check_interval=10,
        timeout=300,
    )

    ingest_data >> transform_daily_product_revenue >> notify_user
