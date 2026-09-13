SELECT
    width_bucket(EXTRACT(EPOCH FROM (r2.purchase_ts - r1.purchase_ts)), 0, 300, 10) AS bucket,
    COUNT(*)
FROM ranked_orders r1
JOIN ranked_orders r2 ON r1.customer_unique_id = r2.customer_unique_id
WHERE r1.rnk = 1 AND r2.rnk = 2
  AND EXTRACT(EPOCH FROM (r2.purchase_ts - r1.purchase_ts)) BETWEEN 0 AND 300
GROUP BY 1 ORDER BY 1;