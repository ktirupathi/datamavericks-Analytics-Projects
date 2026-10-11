-- E-commerce Delivery Performance & Customer Retention Analysis
-- File: sql/01_load.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 3 — Load into PostgreSQL
-- ============================================================
CREATE TABLE raw_orders (
  order_id TEXT, customer_id TEXT, order_status TEXT, order_purchase_timestamp TEXT,
  order_approved_at TEXT, order_delivered_carrier_date TEXT,
  order_delivered_customer_date TEXT, order_estimated_delivery_date TEXT);

CREATE TABLE raw_customers (
  customer_id TEXT, customer_unique_id TEXT, customer_zip_code_prefix TEXT,
  customer_city TEXT, customer_state TEXT);

CREATE TABLE raw_order_items (
  order_id TEXT, order_item_id TEXT, product_id TEXT, seller_id TEXT,
  shipping_limit_date TEXT, price TEXT, freight_value TEXT);

CREATE TABLE raw_reviews (
  review_id TEXT, order_id TEXT, review_score TEXT, review_comment_title TEXT,
  review_comment_message TEXT, review_creation_date TEXT, review_answer_timestamp TEXT);

CREATE TABLE raw_products (
  product_id TEXT, product_category_name TEXT, product_name_lenght TEXT,
  product_description_lenght TEXT, product_photos_qty TEXT, product_weight_g TEXT,
  product_length_cm TEXT, product_height_cm TEXT, product_width_cm TEXT);

CREATE TABLE raw_sellers (
  seller_id TEXT, seller_zip_code_prefix TEXT, seller_city TEXT, seller_state TEXT);

CREATE TABLE raw_category_translation (
  product_category_name TEXT, product_category_name_english TEXT);

SELECT 'orders' AS t, COUNT(*) FROM raw_orders
UNION ALL SELECT 'customers', COUNT(*) FROM raw_customers
UNION ALL SELECT 'items', COUNT(*) FROM raw_order_items
UNION ALL SELECT 'reviews', COUNT(*) FROM raw_reviews
UNION ALL SELECT 'products', COUNT(*) FROM raw_products
UNION ALL SELECT 'sellers', COUNT(*) FROM raw_sellers
UNION ALL SELECT 'translation', COUNT(*) FROM raw_category_translation;
