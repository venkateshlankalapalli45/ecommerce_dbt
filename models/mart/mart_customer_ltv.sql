-- grain: one row per person (96,096 rows)
with customers as (
    select * from {{ ref('int_customer_orders') }}
),

segmented as (
    select
        c.*,

        case
            when lifetime_revenue >= 1000 then 'high_value'
            when lifetime_revenue >= 300  then 'mid_value'
            when lifetime_revenue > 0     then 'low_value'
            else 'no_purchase'
        end as value_segment,

        case
            when valid_orders = 0        then 'never_purchased'
            when days_since_last_order <= 90  then 'active'
            when days_since_last_order <= 180 then 'at_risk'
            else 'churned'
        end as lifecycle_stage,

        ntile(10) over (order by lifetime_revenue desc) as revenue_decile

    from customers c
)

select * from segmented