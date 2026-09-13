WITH
    valid_orders AS (
        SELECT
            order_id, customer_id,
            NULLIF(TRIM(order_purchase_timestamp), '')::timestamp AS purchase_ts,
            NULLIF(TRIM(order_delivered_customer_date), '')::date AS delivered_date,
            NULLIF(TRIM(order_estimated_delivery_date), '')::date AS estimated_date
        FROM
            target.orders
        WHERE
            order_status = 'delivered'
            AND NULLIF(TRIM(order_estimated_delivery_date), '') IS NOT NULL
            AND NULLIF(TRIM(order_delivered_customer_date), '') IS NOT NULL
    ),

    first_valid_order AS (
        SELECT
            c.customer_unique_id,
            MIN(vo.purchase_ts) AS first_purchase
        FROM
            target.customers c
        JOIN
            valid_orders vo ON c.customer_id = vo.customer_id
        GROUP BY 1
    ),

    dataset_end AS (
        SELECT MAX(NULLIF(TRIM(order_purchase_timestamp), '')::timestamp) AS max_ts
        FROM target.orders
    )

SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN fvo.first_purchase <= de.max_ts - INTERVAL '60 days' THEN 1 ELSE 0 END) AS eligible_w60,
    SUM(CASE WHEN fvo.first_purchase <= de.max_ts - INTERVAL '90 days' THEN 1 ELSE 0 END) AS eligible_w90,
    SUM(CASE WHEN fvo.first_purchase <= de.max_ts - INTERVAL '180 days' THEN 1 ELSE 0 END) AS eligible_w180,
    SUM(CASE WHEN fvo.first_purchase <= de.max_ts - INTERVAL '281 days' THEN 1 ELSE 0 END) AS eligible_w281
FROM
    first_valid_order fvo, dataset_end de