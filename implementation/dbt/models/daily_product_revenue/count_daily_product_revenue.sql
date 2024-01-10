{{ config(materialized='table') }}

select order_date, order_item_product_id, round(sum(order_item_subtotal), 2) as revenue
from {{ ref('order_details') }}
where order_status in ('COMPLETE', 'CLOSED')
group by 1, 2