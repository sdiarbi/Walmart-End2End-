with source as (
    select * from {{ source('raw_walmart', 'DEPARTMENT') }}
)

select
    cast(store as integer)                            as store_id,
    cast(dept as integer)                             as dept_id,
    try_to_date(date)::DATE                           as date,
    cast(weekly_sales as numeric(12, 2))              as weekly_sales,
    cast(isholiday as boolean)                        as isholiday
from source