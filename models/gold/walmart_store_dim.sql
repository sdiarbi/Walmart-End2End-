{{ config(materialized='table') }}

with silver_joined as (
    select * from {{ ref('int_walmart_sales_joined') }}
),

dept_stg as (
    select distinct store_id, dept_id from {{ ref('stg_department') }}
)

select distinct
    s.store_id,
    d.dept_id,
    s.store_type,
    s.store_size,
    current_timestamp() as insert_date,
    current_timestamp() as update_date
from silver_joined s
left join dept_stg d
    on s.store_id = d.store_id