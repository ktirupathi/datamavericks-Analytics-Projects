-- Marketing Channel Attribution & Conversion Funnel Analysis
-- File: sql/01_load.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 3 — Load into PostgreSQL
-- ============================================================
CREATE TABLE raw_sessions (website_session_id TEXT, created_at TEXT, user_id TEXT, is_repeat_session TEXT,
  utm_source TEXT, utm_campaign TEXT, utm_content TEXT, device_type TEXT, http_referer TEXT);
CREATE TABLE raw_pageviews (website_pageview_id TEXT, created_at TEXT, website_session_id TEXT, pageview_url TEXT);
CREATE TABLE raw_orders (order_id TEXT, created_at TEXT, website_session_id TEXT, user_id TEXT,
  primary_product_id TEXT, items_purchased TEXT, price_usd TEXT, cogs_usd TEXT);
CREATE TABLE raw_order_items (order_item_id TEXT, created_at TEXT, order_id TEXT, product_id TEXT,
  is_primary_item TEXT, price_usd TEXT, cogs_usd TEXT);
CREATE TABLE raw_refunds (order_item_refund_id TEXT, created_at TEXT, order_item_id TEXT, order_id TEXT, refund_amount_usd TEXT);
CREATE TABLE raw_products (product_id TEXT, created_at TEXT, product_name TEXT);
