with source as (

    select * from {{ source('raw', 'raw_category_translation') }}

),

renamed as (

    select
        product_category_name          as category_name_pt,
        product_category_name_english  as category_name_en

    from source

)

select * from renamed