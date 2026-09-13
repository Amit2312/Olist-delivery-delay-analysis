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
	delay_orders AS (
		SELECT
			CASE
				WHEN vo.delivered_date > vo.estimated_date THEN 'delay'
				ELSE 'on-time'
			END AS delivery,
			vo.order_id,
			oi.price,
			oi.freight_value
		FROM
			target.order_items oi
			JOIN valid_orders vo ON oi.order_id = vo.order_id
	)
SELECT
	round(sum(price + freight_value)::numeric / count(DISTINCT order_id), 2) AS avg_order_value
FROM
	delay_orders
WHERE
	delivery = 'delay'