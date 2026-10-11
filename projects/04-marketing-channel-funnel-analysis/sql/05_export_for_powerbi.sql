-- Marketing Channel Attribution & Conversion Funnel Analysis
-- File: sql/05_export_for_powerbi.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 11 — Export and model
-- ============================================================
SELECT created_at::date AS day, channel, device_type,
  COUNT(*) AS sessions, COUNT(order_id) AS orders,
  COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(cogs), 0) AS cogs
FROM sessions_ch GROUP BY 1, 2, 3;
