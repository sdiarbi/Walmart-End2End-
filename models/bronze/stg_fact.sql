with source as (
    select * from {{ source('raw_walmart', 'FACT') }}
)

select
    cast(store as integer)                            as store_id,
    try_to_date(date)::DATE                           as date,
    cast(temperature as float)                        as temperature,
    cast(fuel_price as numeric(10, 3))                as fuel_price,
    nullif(markdown1, 'NA')::numeric(10, 2)           as markdown1,
    nullif(markdown2, 'NA')::numeric(10, 2)           as markdown2,
    nullif(markdown3, 'NA')::numeric(10, 2)           as markdown3,
    nullif(markdown4, 'NA')::numeric(10, 2)           as markdown4,
    nullif(markdown5, 'NA')::numeric(10, 2)           as markdown5,
    nullif(cpi, 'NA')::numeric(10, 4)                 as cpi,
    nullif(unemployment, 'NA')::numeric(10, 3)        as unemployment,
    cast(isholiday as boolean)                        as isholiday
from source