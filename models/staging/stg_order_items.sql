with source as (

    select * from {{ source('raw', 'raw_order_items') }}

),

renamed as (

    select
        order_id,
        try_to_number(order_item_id)          as order_item_number,  -- 1,2,3 within an order
        product_id,
        seller_id,

        try_to_timestamp(shipping_limit_date) as shipping_limit_at,
        try_to_double(price)                  as item_price,
        try_to_double(freight_value)          as freight_value

    from source

)

select * from renamed