{{ config(materialized='view') }}

select
    order_id::integer as order_id,
    customer_id::integer as customer_id,
    order_date::date as order_date,
    amount::decimal(10, 2) as amount
from {{ ref('raw_orders') }}
