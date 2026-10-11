-- Marketing Channel Attribution & Conversion Funnel Analysis
-- File: sql/03_clean_and_channels.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 5 — Clean and build the channel view
-- ============================================================
CREATE TABLE sessions AS
SELECT website_session_id::int AS session_id,
  created_at::timestamp AS created_at,
  user_id::int AS user_id,
  is_repeat_session::int AS is_repeat,
  NULLIF(NULLIF(utm_source, ''), 'NULL')   AS utm_source,
  NULLIF(NULLIF(utm_campaign, ''), 'NULL') AS utm_campaign,
  device_type,
  NULLIF(NULLIF(http_referer, ''), 'NULL') AS http_referer
FROM raw_sessions;

CREATE TABLE orders AS
SELECT order_id::int, created_at::timestamp, website_session_id::int AS session_id,
       price_usd::numeric AS revenue, cogs_usd::numeric AS cogs
FROM raw_orders;

CREATE TABLE pageviews AS
SELECT website_pageview_id::int AS pageview_id, website_session_id::int AS session_id, pageview_url
FROM raw_pageviews;

CREATE VIEW sessions_ch AS
SELECT s.*,
  CASE
    WHEN s.utm_campaign = 'nonbrand'                         THEN 'Paid search – nonbrand'
    WHEN s.utm_campaign = 'brand'                            THEN 'Paid search – brand'
    WHEN s.utm_source = 'socialbook'                         THEN 'Paid social'
    WHEN s.utm_source IS NULL AND s.http_referer IS NOT NULL THEN 'Organic search'
    WHEN s.utm_source IS NULL AND s.http_referer IS NULL     THEN 'Direct type-in'
    ELSE 'Other' END AS channel,
  o.order_id, o.revenue, o.cogs
FROM sessions s
LEFT JOIN orders o ON o.session_id = s.session_id;
