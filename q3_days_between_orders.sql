WITH
	ranked_orders AS (
		SELECT
			c.customer_unique_id,
			o.order_id,
			NULLIF(TRIM(o.order_purchase_timestamp), '')::timestamp AS purchase_ts,
			ROW_NUMBER() OVER (
				PARTITION BY
					c.customer_unique_id
				ORDER BY
					NULLIF(TRIM(o.order_purchase_timestamp), '')::timestamp,
					o.order_id
			) AS rnk
		FROM
			target.orders o
			JOIN target.customers c ON o.customer_id = c.customer_id
		WHERE
			NULLIF(TRIM(o.order_purchase_timestamp), '') IS NOT NULL
	)
SELECT
	r1.customer_unique_id,
	r1.order_id AS first_order_id,
	r2.order_id AS second_order_id,
	extract(
		epoch
		FROM
			(r2.purchase_ts - r1.purchase_ts) / 86400
	) AS days_between_orders
FROM
	ranked_orders r1
	JOIN ranked_orders r2 ON r1.customer_unique_id = r2.customer_unique_id
WHERE
	r1.rnk = 1
	AND r2.rnk = 2
	AND extract(
		epoch
		FROM
			(r2.purchase_ts - r1.purchase_ts)
	) > 60
ORDER BY
	4 DESC