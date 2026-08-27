-- grain: one row per month (~25 rows)
with orders as (
    select * from {{ ref('int_orders_enriched') }}
    where order_status != 'canceled'
),

monthly as (
    select
        order_month,
        count(*)                            as total_orders,
        count(distinct customer_unique_id)  as unique_customers,
        sum(order_revenue)                  as total_revenue,
        sum(items_revenue)                  as product_revenue,
        sum(freight_revenue)                as shipping_revenue,
        sum(item_count)                     as total_items_sold,
        avg(order_revenue)                  as avg_order_value,
        avg(avg_review_score)               as avg_review_score,
        avg(delivery_days)                  as avg_delivery_days
    from orders
    group by 1
),

with_growth as (
    select
        m.*,
        lag(total_revenue) over (order by order_month) as prev_month_revenue,
        round(
            100.0 * (total_revenue - lag(total_revenue) over (order by order_month))
            / nullif(lag(total_revenue) over (order by order_month), 0)
        , 2) as revenue_growth_pct
    from monthly m
)

select * from with_growth
order by order_month