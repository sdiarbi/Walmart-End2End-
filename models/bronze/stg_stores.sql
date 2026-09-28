with source as (
    select * from {{ source('raw_walmart', 'STORES') }}
)

select
    cast(store as integer)        as store_id,
    cast(type as varchar(10))     as store_type,
    cast(size as integer)         as store_size
from source