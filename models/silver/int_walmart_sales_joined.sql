{{ config(materialized='table') }}

with fact as (
    select * from {{ ref('stg_fact') }}
),

stores as (
    select * from {{ ref('stg_stores') }}
)

select
    -- Fact columns
    fact.store_id,
    fact.date,
    fact.temperature,
    fact.fuel_price,
    fact.markdown1,
    fact.markdown2,
    fact.markdown3,
    fact.markdown4,
    fact.markdown5,
    fact.cpi,
    fact.unemployment,
    fact.isholiday,

    -- Store metadata
    stores.store_type,
    stores.store_size

from fact
left join stores
    on fact.store_id = stores.store_id