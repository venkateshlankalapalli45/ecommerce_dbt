with source as (

    select * from {{ source('raw', 'raw_orders') }}

),

renamed as (

    select
        order_id,
        customer_id,              -- joins to stg_customers; per-order, not per-person
        order_status,

        try_to_timestamp(order_purchase_timestamp)      as purchased_at,
        try_to_timestamp(order_approved_at)             as approved_at,
        try_to_timestamp(order_delivered_carrier_date)  as shipped_at,
        try_to_timestamp(order_delivered_customer_date) as delivered_at,
        try_to_timestamp(order_estimated_delivery_date) as estimated_delivery_at

    from source

)

select * from renamed