-- NOTE: because this model uses the format_currency macro at /macros/format_currency.sql, which then references the 
--       usd_currency_conversion seed at /seeds/usd_currency_conversion.csv,
--       we need to manually let dbt know that in some way this model references that seed so that it can detect the dependency -
--       otherwise there will be an error on build. Do this with the "depends_on" comment below:

-- depends_on: {{ ref('usd_currency_conversion') }}

with customer_orders as (

    select * from {{ ref('int__customer_orders') }}

),

order_items as (

    select * from {{ ref('int__order_items') }}

),

orders_snapshot as (

    select * from {{ ref('snap__orders') }}

),

-- get all order changes within data retention period (variable is set to 90 days in dbt_project.yml)
-- NOTE: the orders snapshot (at: /snapshots/snap__orders.sql) may have multiple records per order_id, one for each occurence of a snapshotted record change to an order
count_order_updates as (

    select
        o_orderkey as order_id,
        o_custkey as customer_id,
        min(dbt_valid_from) as order_submission_date,
        max(dbt_valid_from) as last_order_change_date, -- will be same as order_submission_date if only 1 snapshot record exists for the order
        count(*) as total_order_updates
    from
        orders_snapshot
    group by
        order_id,
        customer_id
    having 
        order_submission_date >= DATEADD(day, -{{ var('data_retention_days') }}, CURRENT_DATE)

),

-- combine final order information
customer_order_with_updates as (

    select
        count_order_updates.order_id,
        count_order_updates.order_submission_date,
        count_order_updates.last_order_change_date,
        count_order_updates.total_order_updates,
        order_items.low_cost_items,
        order_items.mid_cost_items,
        order_items.high_cost_items,
        order_items.total_order_size,
        order_items.status,
        order_items.priority_int,
        customer_orders.customer_id,
        customer_orders.customer_name,

        -- get amount in default configured currency, after multiplying by conversion factor (macro at: /macros/format_currency.sql)
        {{ format_currency('order_items.total_line_amount', var('default_currency_type')) }} as total_amount,

        -- get amount in Euros, after multiplying by conversion factor (macro at: /macros/format_currency.sql)
        {{ format_currency('order_items.total_line_amount', 'EUR') }} as total_amount_euro,

        -- get amount in Japanese Yen, after multiplying by conversion factor (macro at: /macros/format_currency.sql)
        {{ format_currency('order_items.total_line_amount', 'JPY') }} as total_amount_yen
    from
        count_order_updates
    join
        customer_orders using (customer_id)
    join
        order_items using (order_id)

)

select * from customer_order_with_updates