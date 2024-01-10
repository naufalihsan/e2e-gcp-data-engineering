import datetime

from airflow import models
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocInstantiateWorkflowTemplateOperator,
)
from airflow.utils.dates import days_ago

project_id = "e2e-pipeline-cs"
region = "asia-southeast2"

default_args = {
    "project_id": project_id,
    "region": region,
    # Tell airflow to start one day ago, so that it runs as soon as you upload it
    "start_date": days_ago(1)
}

with models.DAG(
    "daily_product_revenue_workflow_dag",
    default_args=default_args,
    # The interval with which to schedule the DAG
    schedule_interval=datetime.timedelta(days=1), 
) as dag:

    start_template_job = DataprocInstantiateWorkflowTemplateOperator(
        # The task id of Airflow job
        task_id="daily_product_revenue_workflow",
        # The template id of Dataproc workflow
        template_id="e2e-gcp-data-pipeline"
    )