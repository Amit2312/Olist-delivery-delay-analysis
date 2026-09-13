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
),
valid_reviews AS (
    SELECT
        order_id,
        review_score,
        ROW_NUMBER() OVER (
            PARTITION BY order_id
            ORDER BY
                TO_TIMESTAMP(review_creation_date, 'DD/MM/YY HH24:MI')::date DESC,
                TO_TIMESTAMP(review_answer_timestamp, 'DD/MM/YY HH24:MI') DESC,
                review_id DESC
        ) AS rnk
    FROM target.order_reviews
)
SELECT
    CASE WHEN vo.delivered_date > vo.estimated_date THEN 'delay' ELSE 'on_time' END AS delivery,
    ROUND(AVG(vr.review_score), 2) AS avg_review_score,
    COUNT(*) AS num_of_orders
FROM valid_orders vo
JOIN valid_reviews vr ON vo.order_id = vr.order_id
WHERE vr.rnk = 1
GROUP BY 1