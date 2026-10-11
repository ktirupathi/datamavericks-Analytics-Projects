-- Marketing Channel Attribution & Conversion Funnel Analysis
-- File: sql/02_explore.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 4 — Explore
-- ============================================================
-- What tracking values exist? (look for blanks or the text 'NULL')
SELECT utm_source, utm_campaign, COUNT(*) FROM raw_sessions GROUP BY 1, 2 ORDER BY 3 DESC;
SELECT http_referer, COUNT(*) FROM raw_sessions GROUP BY 1 ORDER BY 2 DESC;
SELECT device_type, COUNT(*) FROM raw_sessions GROUP BY 1;

-- Every page on the site (these become your funnel steps)
SELECT pageview_url, COUNT(*) FROM raw_pageviews GROUP BY 1 ORDER BY 2 DESC;

-- Date range, and is every order linked to a session?
SELECT MIN(created_at), MAX(created_at) FROM raw_sessions;
SELECT COUNT(*) FROM raw_orders o LEFT JOIN raw_sessions s ON s.website_session_id = o.website_session_id
WHERE s.website_session_id IS NULL;
