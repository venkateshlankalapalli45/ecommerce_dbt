with source as (

    select * from {{ source('raw', 'raw_order_reviews') }}

),

renamed as (

    select
        review_id,                -- NOT unique: 99,224 rows, 98,410 distinct values
        order_id,
        try_to_number(review_score)               as review_score,
        review_comment_title,
        review_comment_message,

        try_to_timestamp(review_creation_date)    as review_created_at,
        try_to_timestamp(review_answer_timestamp) as review_answered_at

    from source

)

select * from renamed