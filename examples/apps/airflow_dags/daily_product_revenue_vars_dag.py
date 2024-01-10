import datetime

from airflow import models
from airflow.models import Variable
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocInstantiateWorkflowTemplateOperator,
)
from airflow.utils.dates import days_ago

project_id = Variable.get('project_id')
region = Variable.get('region')

default_args = {
    "project_id": project_id,
    "region": region,
    "start_date": days_ago(1)
}

with models.DAG(
    "daily_product_revenue_vars_wf_dag",
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