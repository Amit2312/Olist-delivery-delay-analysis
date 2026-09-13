SELECT order_id, count(*) as review_count, array_agg(review_score) as scores
FROM target.order_reviews
GROUP BY 1
HAVING count(*) > 1