-- schema.sql
-- Olist Brazilian e-commerce dataset, target schema
-- Reference only: reflects table structure used in this analysis, not a runnable CREATE script
-- for the original dataset (see README for data source).
-- Column types confirmed directly from the working Postgres database via TablePlus.

CREATE TABLE target.customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

CREATE TABLE target.orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    -- NOTE: all date/timestamp columns below are stored as TEXT in source data.
    -- Cast explicitly before comparing, e.g. NULLIF(TRIM(col), '')::timestamp
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

CREATE TABLE target.order_items (
    order_id TEXT,
    order_item_id TEXT,  -- NOTE: confirmed as text in this DB; unusual (normally a small int counter) -- double-check if this looks wrong
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price FLOAT8,       -- stored as float8; explains trailing-decimal artifacts (e.g. ...998734) in SUM() results
    freight_value FLOAT8
);

CREATE TABLE target.order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    -- NOTE: stored as TEXT in 'DD/MM/YY HH24:MI' format.
    -- Requires TO_TIMESTAMP(col, 'DD/MM/YY HH24:MI'), not a plain cast.
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

CREATE TABLE target.payments (
    order_id TEXT,
    payment_sequential INTEGER,
    payment_type TEXT,
    payment_installments INTEGER,
    payment_value FLOAT8
);

CREATE TABLE target.products (
    product_id TEXT,
    product_category TEXT,
    product_name_length INTEGER,
    product_description_length INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER
);

CREATE TABLE target.sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
)