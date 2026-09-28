{{ config(materialized='table') }}

with silver_joined as (
    select * from {{ ref('int_walmart_sales_joined') }}
)

select distinct
    row_number() over (order by date) as date_id,
    date as store_date,
    cast(isholiday as varchar) as isholiday,
    current_timestamp() as insert_date,
    current_timestamp() as update_date
from silver_joined