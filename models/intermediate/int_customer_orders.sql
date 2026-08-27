-- grain: one row per PERSON (customer_unique_id), ~96,096 rows
with orders as (
    select * from {{ ref('int_orders_enriched') }}
),

-- the dataset ends in Oct 2018, so "days since last order"
-- has to be measured against the data's own end date, not today
dataset_end as (
    select max(purchased_at) as last_date_in_data from orders
),

final as (
    select
        o.customer_unique_id,

        -- location: a person can have several customer_ids with
        -- different addresses. max() picks one deterministically.
        max(o.customer_city)  as customer_city,
        max(o.customer_state) as customer_state,

        -- order counts
        count(*)                                                        as total_orders,
        count(case when o.order_status = 'canceled' then 1 end)         as cancelled_orders,
        count(case when o.order_status != 'canceled' then 1 end)        as valid_orders,

        -- revenue: cancelled orders earned nothing, so exclude them
        sum(case when o.order_status != 'canceled' then o.order_revenue else 0 end) as lifetime_revenue,
        sum(case when o.order_status != 'canceled' then o.item_count    else 0 end) as lifetime_items,

        -- dates: first/last real purchase, ignoring cancellations
        min(case when o.order_status != 'canceled' then o.purchased_at end) as first_order_at,
        max(case when o.order_status != 'canceled' then o.purchased_at end) as last_order_at,

        -- experience
        avg(o.avg_review_score) as avg_review_score,
        avg(o.delivery_days)    as avg_delivery_days,
        count(case when o.is_late_delivery then 1 end) as late_deliveries

    from orders o
    group by 1
),

with_derived as (
    select
        f.*,

        -- average order value, guarded against divide-by-zero
        case
            when f.valid_orders > 0 then f.lifetime_revenue / f.valid_orders
            else 0
        end as avg_order_value,

        f.valid_orders > 1 as is_repeat_customer,

        -- how long they stayed active
        datediff('day', f.first_order_at, f.last_order_at) as customer_lifespan_days,

        -- recency, measured against the dataset's end
        datediff('day', f.last_order_at, d.last_date_in_data) as days_since_last_order

    from final f
    cross join dataset_end d
)

select * from with_derived