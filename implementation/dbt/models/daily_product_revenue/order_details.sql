{{ config(materialized='table') }}

select * 
from {{ ref('orders') }} as o
    join {{ ref('order_items') }} as oi on o.order_id = oi.order_item_order_id