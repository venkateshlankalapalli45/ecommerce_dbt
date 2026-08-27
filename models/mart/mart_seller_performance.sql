-- grain: one row per seller (~3,095 rows)
with items as (
    select * from {{ ref('int_order_items_enriched') }}
    where order_status != 'canceled'
),

by_seller as (
    select
        seller_id,
        max(seller_city)  as seller_city,
        max(seller_state) as seller_state,

        count(*)                        as items_sold,
        count(distinct order_id)        as total_orders,
        count(distinct product_id)      as distinct_products,
        count(distinct product_category) as distinct_categories,

        sum(item_revenue)  as total_revenue,
        sum(item_price)    as product_revenue,
        sum(freight_value) as shipping_revenue,
        avg(item_price)    as avg_item_price,

        min(purchased_at) as first_sale_at,
        max(purchased_at) as last_sale_at,
        datediff('day', min(purchased_at), max(purchased_at)) as active_days

    from items
    group by 1
),

ranked as (
    select
        s.*,
        case when total_orders > 0 then total_revenue / total_orders else 0 end as revenue_per_order,
        rank() over (order by total_revenue desc) as revenue_rank
    from by_seller s
)

select * from ranked