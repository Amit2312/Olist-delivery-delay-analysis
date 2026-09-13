WITH valid_orders AS (
    SELECT
        order_id, customer_id,
        NULLIF(TRIM(order_purchase_timestamp), '')::timestamp AS purchase_ts,
        NULLIF(TRIM(order_delivered_customer_date), '')::date AS delivered_date,
        NULLIF(TRIM(order_estimated_delivery_date), '')::date AS estimated_date
    FROM target.orders
    WHERE order_status = 'delivered'
        AND NULLIF(TRIM(order_estimated_delivery_date), '') IS NOT NULL
        AND NULLIF(TRIM(order_delivered_customer_date), '') IS NOT NULL
),

first_orders AS (
    SELECT
        customer_unique_id,
        purchase_ts AS first_order,
        CASE WHEN delivered_date > estimated_date THEN 'delay' ELSE 'on-time' END AS delivery
    FROM (
        SELECT
            c.customer_unique_id,
            vo.purchase_ts,
            vo.delivered_date,
            vo.estimated_date,
            ROW_NUMBER() OVER (
                PARTITION BY c.customer_unique_id
                ORDER BY vo.purchase_ts, vo.order_id
            ) AS rnk
        FROM target.customers c
        JOIN valid_orders vo ON c.customer_id = vo.customer_id
    ) ranked
    WHERE rnk = 1
),

eligible_customers AS (
    SELECT customer_unique_id, first_order, delivery
    FROM first_orders
    WHERE first_order <= (
        SELECT MAX(NULLIF(TRIM(order_purchase_timestamp), '')::timestamp)
        FROM target.orders
    ) - INTERVAL '180 days'
),

all_orders_uid AS (
    SELECT
        c.customer_unique_id,
        NULLIF(TRIM(o.order_purchase_timestamp), '')::timestamp AS purchase_ts
    FROM target.orders o
    JOIN target.customers c ON o.customer_id = c.customer_id
    WHERE NULLIF(TRIM(o.order_purchase_timestamp), '') IS NOT NULL
),

reorder_flag AS (
    SELECT
        ec.customer_unique_id,
        ec.delivery,
        MAX(
            CASE WHEN ao.purchase_ts > ec.first_order
                  AND ao.purchase_ts <= ec.first_order + INTERVAL '180 days'
                 THEN 1 ELSE 0 END
        ) AS reordered
    FROM eligible_customers ec
    LEFT JOIN all_orders_uid ao ON ao.customer_unique_id = ec.customer_unique_id
    GROUP BY ec.customer_unique_id, ec.delivery
)

SELECT
    delivery,
    COUNT(*) AS total_eligible,
    SUM(reordered) AS reordered_count,
    ROUND(100.0 * SUM(reordered) / COUNT(*), 2) AS reorder_rate_pct
FROM reorder_flag
GROUP BY delivery