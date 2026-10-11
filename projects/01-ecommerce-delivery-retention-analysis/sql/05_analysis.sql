-- E-commerce Delivery Performance & Customer Retention Analysis
-- File: sql/05_analysis.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 7 — Q1: How often are we late?
-- ============================================================
SELECT ROUND(AVG(is_late) * 100, 1) AS late_pct, COUNT(*) AS delivered_orders FROM order_facts;

SELECT purchase_month, COUNT(*) AS orders, ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM order_facts
GROUP BY 1 HAVING COUNT(*) >= 500   -- skip thin months at the start and end
ORDER BY 1;


-- ============================================================
-- Day 8 — Q2: How much does lateness hurt reviews?
-- ============================================================
SELECT
  CASE WHEN days_late <= 0 THEN '1. On time or early'
       WHEN days_late <= 3 THEN '2. 1–3 days late'
       WHEN days_late <= 7 THEN '3. 4–7 days late'
       ELSE '4. 8+ days late' END                         AS delivery_bucket,
  COUNT(*)                                                AS orders,
  ROUND(AVG(review_score), 2)                             AS avg_review,
  ROUND(AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) * 100, 1) AS bad_review_pct
FROM order_facts
WHERE review_score IS NOT NULL
GROUP BY 1 ORDER BY 1;


-- ============================================================
-- Day 9 — Q3 & Q4: Do customers come back?
-- ============================================================
-- Q3. What % of real customers ever ordered again?
SELECT COUNT(*) AS customers,
       SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(AVG(CASE WHEN orders > 1 THEN 1 ELSE 0 END) * 100, 2) AS repeat_pct
FROM (SELECT customer_unique_id, COUNT(*) AS orders FROM order_facts GROUP BY 1) t;

-- Q4. Does a late FIRST order reduce coming back?
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_date) AS order_no,
    COUNT(*)     OVER (PARTITION BY customer_unique_id)                         AS total_orders
  FROM order_facts)
SELECT
  CASE WHEN is_late = 1 THEN 'First order late' ELSE 'First order on time' END AS first_experience,
  COUNT(*) AS customers,
  ROUND(AVG(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100, 2) AS came_back_pct
FROM ranked
WHERE order_no = 1
GROUP BY 1;


-- ============================================================
-- Day 10 — Q5: Where does lateness happen?
-- ============================================================
-- By customer state
SELECT customer_state, COUNT(*) AS orders, ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM order_facts GROUP BY 1 HAVING COUNT(*) >= 300 ORDER BY late_pct DESC;

-- By product category (an order can have several categories; count each order-category pair once)
SELECT p.category, COUNT(DISTINCT f.order_id) AS orders, ROUND(AVG(f.is_late) * 100, 1) AS late_pct
FROM order_facts f
JOIN order_items i ON i.order_id = f.order_id
JOIN products p    ON p.product_id = i.product_id
GROUP BY 1 HAVING COUNT(DISTINCT f.order_id) >= 300 ORDER BY late_pct DESC;

-- Seller state → customer state routes
SELECT s.seller_state, f.customer_state, COUNT(DISTINCT f.order_id) AS orders,
       ROUND(AVG(f.is_late) * 100, 1) AS late_pct
FROM order_facts f
JOIN order_items i ON i.order_id = f.order_id
JOIN sellers s     ON s.seller_id = i.seller_id
GROUP BY 1, 2 HAVING COUNT(DISTINCT f.order_id) >= 300 ORDER BY late_pct DESC LIMIT 15;
