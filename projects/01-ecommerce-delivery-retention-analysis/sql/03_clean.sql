-- E-commerce Delivery Performance & Customer Retention Analysis
-- File: sql/03_clean.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 5 — Clean
-- ============================================================
-- Orders: proper timestamps
CREATE TABLE orders AS
SELECT order_id, customer_id, order_status,
  NULLIF(order_purchase_timestamp, '')::timestamp      AS purchase_ts,
  NULLIF(order_delivered_customer_date, '')::timestamp AS delivered_ts,
  NULLIF(order_estimated_delivery_date, '')::timestamp AS estimated_ts
FROM raw_orders;

-- Customers: unchanged, just typed
CREATE TABLE customers AS
SELECT customer_id, customer_unique_id, customer_city, customer_state FROM raw_customers;

-- Reviews: keep ONE review per order (the latest)
CREATE TABLE reviews AS
SELECT order_id, review_score::int AS review_score
FROM (
  SELECT order_id, review_score, review_creation_date,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date DESC) AS rn
  FROM raw_reviews) t
WHERE rn = 1;

-- Items with numbers
CREATE TABLE order_items AS
SELECT order_id, order_item_id::int AS item_no, product_id, seller_id,
       price::numeric AS price, freight_value::numeric AS freight
FROM raw_order_items;

-- Products with English category
CREATE TABLE products AS
SELECT p.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
FROM raw_products p
LEFT JOIN raw_category_translation t ON t.product_category_name = p.product_category_name;

CREATE TABLE sellers AS SELECT seller_id, seller_state FROM raw_sellers;
