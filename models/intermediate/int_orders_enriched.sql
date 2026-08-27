-- grain: one row per order (99,441 rows)

with orders as (

    select * from {{ ref('stg_orders') }}

),

customers as (

    select * from {{ ref('stg_customers') }}

),

-- collapse line items to ONE row per order before joining
item_totals as (

    select
        order_id,
        count(*)                as item_count,
        count(distinct product_id) as distinct_product_count,
        count(distinct seller_id)  as seller_count,
        sum(item_price)         as items_revenue,
        sum(freight_value)      as freight_revenue
    from {{ ref('stg_order_items') }}
    group by 1

),

-- collapse payments to ONE row per order
payment_totals as (

    select
        order_id,
        count(*)                            as payment_count,
        sum(payment_value)                  as total_paid,
        max(installment_count)              as max_installments,
        listagg(distinct payment_type, ', ') as payment_types
    from {{ ref('stg_order_payments') }}
    group by 1

),

-- collapse reviews to ONE row per order
review_summary as (

    select
        order_id,
        avg(review_score)  as avg_review_score,
        count(*)           as review_count
    from {{ ref('stg_order_reviews') }}
    group by 1

),

final as (

    select
        o.order_id,
        c.customer_unique_id,        -- the PERSON, not the per-order id
        o.customer_id,
        c.customer_city,
        c.customer_state,

        o.order_status,
        o.purchased_at,
        o.approved_at,
        o.shipped_at,
        o.delivered_at,
        o.estimated_delivery_at,

        date_trunc('month', o.purchased_at) as order_month,

        -- business logic lives here, not in staging
        datediff('day', o.purchased_at, o.delivered_at)          as delivery_days,
        datediff('day', o.estimated_delivery_at, o.delivered_at) as days_vs_estimate,
        case
            when o.delivered_at is null then null
            when o.delivered_at > o.estimated_delivery_at then true
            else false
        end as is_late_delivery,

        coalesce(i.item_count, 0)             as item_count,
        coalesce(i.distinct_product_count, 0) as distinct_product_count,
        coalesce(i.seller_count, 0)           as seller_count,
        coalesce(i.items_revenue, 0)          as items_revenue,
        coalesce(i.freight_revenue, 0)        as freight_revenue,
        coalesce(i.items_revenue, 0) + coalesce(i.freight_revenue, 0) as order_revenue,

        coalesce(p.payment_count, 0) as payment_count,
        p.total_paid,
        p.max_installments,
        p.payment_types,

        r.avg_review_score,
        coalesce(r.review_count, 0) as review_count

    from orders o
    left join customers c       on o.customer_id = c.customer_id
    left join item_totals i     on o.order_id    = i.order_id
    left join payment_totals p  on o.order_id    = p.order_id
    left join review_summary r  on o.order_id    = r.order_id

)

select * from final