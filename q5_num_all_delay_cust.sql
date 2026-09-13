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
        customer_unique_id, customer_id, purchase_ts AS first_order,
        CASE WHEN delivered_date > estimated_date THEN 'delay' ELSE 'on-time' END AS delivery
    FROM (
        SELECT
            c.customer_unique_id, c.customer_id,
            vo.purchase_ts, vo.delivered_date, vo.estimated_date,
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
    SELECT customer_unique_id, customer_id, first_order, delivery
    FROM first_orders
    WHERE first_order <= (
        SELECT MAX(NULLIF(TRIM(order_purchase_timestamp), '')::timestamp) - INTERVAL '180 days'
        FROM target.orders
    )
)

SELECT COUNT(*) AS eligible_delayed_customers
FROM eligible_customers
WHERE delivery = 'delay'