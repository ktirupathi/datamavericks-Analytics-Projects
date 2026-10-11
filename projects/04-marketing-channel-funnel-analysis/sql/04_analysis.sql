-- Marketing Channel Attribution & Conversion Funnel Analysis
-- File: sql/04_analysis.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 6 — Q1: How have we grown?
-- ============================================================
SELECT DATE_TRUNC('quarter', created_at)::date AS quarter,
  COUNT(*) AS sessions, COUNT(order_id) AS orders,
  ROUND(COUNT(order_id) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(SUM(revenue), 0) AS revenue,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions_ch GROUP BY 1 ORDER BY 1;


-- ============================================================
-- Day 7 — Q2: Which channels pay?
-- ============================================================
SELECT channel,
  COUNT(*) AS sessions,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS share_of_sessions_pct,
  COUNT(order_id) AS orders,
  ROUND(COUNT(order_id) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions_ch GROUP BY 1 ORDER BY sessions DESC;

-- "Free" traffic over time: organic + direct + brand as a share of all sessions
SELECT DATE_TRUNC('quarter', created_at)::date AS quarter,
  ROUND(AVG(CASE WHEN channel IN ('Organic search','Direct type-in','Paid search – brand') THEN 1 ELSE 0 END) * 100, 1) AS brand_driven_pct
FROM sessions_ch GROUP BY 1 ORDER BY 1;


-- ============================================================
-- Day 8 — Q3: Desktop vs mobile
-- ============================================================
SELECT channel, device_type, COUNT(*) AS sessions,
  ROUND(COUNT(order_id) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions_ch
WHERE channel IN ('Paid search – nonbrand', 'Organic search', 'Direct type-in')
GROUP BY 1, 2 ORDER BY 1, 2;


-- ============================================================
-- Day 9 — Q4: Where do visitors drop off?
-- ============================================================
WITH steps AS (
  SELECT session_id,
    MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END)                  AS s1_products,
    MAX(CASE WHEN pageview_url LIKE '/the-%' THEN 1 ELSE 0 END)                   AS s2_product_page,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END)                      AS s3_cart,
    MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END)                  AS s4_shipping,
    MAX(CASE WHEN pageview_url LIKE '/billing%' THEN 1 ELSE 0 END)               AS s5_billing,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END)  AS s6_ordered
  FROM pageviews GROUP BY session_id)
SELECT COUNT(*) AS sessions,
  SUM(s1_products) AS products, SUM(s2_product_page) AS product_page, SUM(s3_cart) AS cart,
  SUM(s4_shipping) AS shipping, SUM(s5_billing) AS billing, SUM(s6_ordered) AS ordered
FROM steps;


-- ============================================================
-- Day 10 — Q5: The maximum affordable bid
-- ============================================================
SELECT device_type, COUNT(*) AS sessions,
  ROUND((SUM(revenue) - SUM(cogs)) / COUNT(*), 2) AS margin_per_session
FROM sessions_ch
WHERE channel = 'Paid search – nonbrand'
GROUP BY 1;
