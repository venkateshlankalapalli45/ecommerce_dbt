-- grain: one row per product (~32,951 rows)
with items as (
    select * from {{ ref('int_order_items_enriched') }}
    where order_status != 'canceled'
),

by_product as (
    select
        product_id,
        max(product_category) as product_category,
        max(product_weight_g) as product_weight_g,
        max(product_photo_count) as product_photo_count,

        count(*)                    as times_sold,
        count(distinct order_id)    as orders_containing,
        count(distinct seller_id)   as seller_count,

        sum(item_revenue)   as total_revenue,
        sum(item_price)     as product_revenue,
        sum(freight_value)  as shipping_revenue,
        avg(item_price)     as avg_price,
        min(item_price)     as min_price,
        max(item_price)     as max_price,

        min(purchased_at) as first_sold_at,
        max(purchased_at) as last_sold_at

    from items
    group by 1
),

ranked as (
    select
        p.*,
        rank() over (order by total_revenue desc) as revenue_rank,
        rank() over (partition by product_category order by total_revenue desc) as rank_in_category
    from by_product p
)

select * from ranked