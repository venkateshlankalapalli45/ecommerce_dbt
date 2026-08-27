with source as (

    select * from {{ source('raw', 'raw_customers') }}

),

renamed as (

    select
        customer_id,                -- unique per ORDER, not per person
        customer_unique_id,         -- the actual person - use this for LTV
        customer_zip_code_prefix,   -- stays text: leading zeros matter
        customer_city,
        customer_state

    from source

)

select * from renamed