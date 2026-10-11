-- E-commerce Delivery Performance & Customer Retention Analysis
-- File: sql/04_build_order_facts.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 6 — Build one analysis table: order\_facts
-- ============================================================
CREATE TABLE order_facts AS
SELECT
  o.order_id,
  c.customer_unique_id,
  c.customer_state,
  o.purchase_ts::date                                AS purchase_date,
  DATE_TRUNC('month', o.purchase_ts)::date           AS purchase_month,
  (o.delivered_ts::date - o.estimated_ts::date)      AS days_late,
  CASE WHEN o.delivered_ts::date > o.estimated_ts::date THEN 1 ELSE 0 END AS is_late,
  (o.delivered_ts::date - o.purchase_ts::date)       AS delivery_days,
  r.review_score
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_ts IS NOT NULL;
