-- E-commerce Delivery Performance & Customer Retention Analysis
-- File: sql/02_explore.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 4 — Explore (the 6 checks)
-- ============================================================
-- Is order_id unique?  (expect rows = unique)
SELECT COUNT(*) AS rows, COUNT(DISTINCT order_id) AS unique_orders FROM raw_orders;

-- What statuses exist?
SELECT order_status, COUNT(*) FROM raw_orders GROUP BY 1 ORDER BY 2 DESC;

-- How many orders have no delivery date, by status?
SELECT order_status, COUNT(*) FROM raw_orders
WHERE order_delivered_customer_date IS NULL OR order_delivered_customer_date = ''
GROUP BY 1 ORDER BY 2 DESC;

-- Real people vs order-level customer ids
SELECT COUNT(DISTINCT customer_id) AS customer_ids, COUNT(DISTINCT customer_unique_id) AS real_customers
FROM raw_customers;

-- Orders with more than one review
SELECT COUNT(*) FROM (SELECT order_id FROM raw_reviews GROUP BY order_id HAVING COUNT(*) > 1) t;

-- Date range
SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) FROM raw_orders;
