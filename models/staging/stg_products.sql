with source as (

    select * from {{ source('raw', 'raw_products') }}

),

renamed as (

    select
        product_id,
        product_category_name,                                    -- Portuguese; translated downstream

        try_to_number(product_name_lenght)        as product_name_length,
        try_to_number(product_description_lenght) as product_description_length,
        try_to_number(product_photos_qty)         as product_photo_count,
        try_to_number(product_weight_g)           as product_weight_g,
        try_to_number(product_length_cm)          as product_length_cm,
        try_to_number(product_height_cm)          as product_height_cm,
        try_to_number(product_width_cm)           as product_width_cm

    from source

)

select * from renamed