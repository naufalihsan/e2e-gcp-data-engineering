{{ config(materialized='table') }}

select * 
from e2e-pipeline-cs.retail_data_warehouse.orders