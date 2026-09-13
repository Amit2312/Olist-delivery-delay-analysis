WITH
	valid_orders AS (
		SELECT
			order_id,
			customer_id,
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
	state_wise_orders AS (
		SELECT
			c.customer_state,
			CASE
				WHEN vo.delivered_date > vo.estimated_date THEN 'delay'
				ELSE 'on-time'
			END AS delivery
		FROM
			target.customers c
			JOIN valid_orders vo ON c.customer_id = vo.customer_id
	)
SELECT
	customer_state,
	count(*) AS total_orders,
	round(
		sum(
			CASE
				WHEN delivery = 'on-time' THEN 1
				ELSE 0
			END
		)::numeric * 100 / count(*),
		2
	) AS on_time_rate,
	round(
		sum(
			CASE
				WHEN delivery = 'delay' THEN 1
				ELSE 0
			END
		)::numeric * 100 / count(*),
		2
	) AS delay_rate
FROM
	state_wise_orders
GROUP BY
	1
ORDER BY
	4 DESC