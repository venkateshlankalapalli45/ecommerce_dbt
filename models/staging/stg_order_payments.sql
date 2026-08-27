with source as (

    select * from {{ source('raw', 'raw_order_payments') }}

),

renamed as (

    select
        order_id,
        try_to_number(payment_sequential)   as payment_sequence_number,
        payment_type,
        try_to_number(payment_installments) as installment_count,
        try_to_double(payment_value)        as payment_value

    from source

)

select * from renamed