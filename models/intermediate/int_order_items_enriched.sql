-- grain: one row per LINE ITEM (112,650 rows)
with items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

sellers as (
    select * from {{ ref('stg_sellers') }}
),

translation as (
    select * from {{ ref('stg_category_translation') }}
),

final as (
    select
        -- keys
        i.order_id,
        i.order_item_number,
        i.product_id,
        i.seller_id,

        -- order context
        o.order_status,
        o.purchased_at,
        o.delivered_at,
        date_trunc('month', o.purchased_at) as order_month,

        -- product context
        p.product_category_name                              as category_pt,
        coalesce(t.category_name_en, p.product_category_name) as product_category,
        p.product_weight_g,
        p.product_length_cm,
        p.product_height_cm,
        p.product_width_cm,
        p.product_photo_count,

        -- seller context
        s.seller_city,
        s.seller_state,

        -- money
        i.item_price,
        i.freight_value,
        i.item_price + i.freight_value as item_revenue

    from items i
    left join orders o      on i.order_id    = o.order_id
    left join products p    on i.product_id  = p.product_id
    left join sellers s     on i.seller_id   = s.seller_id
    left join translation t on p.product_category_name = t.category_name_pt
)

select * from final