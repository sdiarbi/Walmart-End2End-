{{ config(materialized='table') }}

with silver_joined as (
    select * from {{ ref('int_walmart_sales_joined') }}
),

dept_stg as (
    select * from {{ ref('stg_department') }}
)

select
    s.store_id,
    d.dept_id,
    cast(d.weekly_sales as decimal(18,2)) as store_weekly_sales,
    cast(s.fuel_price as decimal(18,2)) as fuel_price,
    cast(s.temperature as decimal(18,2)) as store_temperature,
    cast(s.unemployment as decimal(18,2)) as unemployement,
    cast(s.cpi as decimal(18,2)) as cpi,
    cast(s.markdown1 as decimal(18,2)) as markdown1,
    cast(s.markdown2 as decimal(18,2)) as markdown2,
    cast(s.markdown3 as decimal(18,2)) as markdown3,
    cast(s.markdown4 as decimal(18,2)) as markdown4,
    cast(s.markdown5 as decimal(18,2)) as markdown5,
    current_timestamp() as insert_date,
    current_timestamp() as update_date,
    s.date::timestamp as vrsn_start_date,
    cast(null as timestamp) as vrsn_end_date
from silver_joined s
left join dept_stg d
    on s.store_id = d.store_id
   and s.date = d.date