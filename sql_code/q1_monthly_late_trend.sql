WITH valid_orders AS (
    SELECT
        order_id,
        NULLIF(TRIM(order_purchase_timestamp), '')::timestamp AS purchase_ts,
        NULLIF(TRIM(order_delivered_customer_date), '')::date AS delivered_date,
        NULLIF(TRIM(order_estimated_delivery_date), '')::date AS estimated_date
    FROM target.orders
    WHERE order_status = 'delivered'
        AND NULLIF(TRIM(order_estimated_delivery_date), '') IS NOT NULL
        AND NULLIF(TRIM(order_delivered_customer_date), '') IS NOT NULL
)
SELECT
    DATE_TRUNC('month', purchase_ts)::date AS order_month,
    COUNT(*) AS order_count,
    ROUND(SUM(CASE WHEN delivered_date > estimated_date THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)
     AS share_of_late_orders
FROM valid_orders
GROUP BY 1
ORDER BY 1