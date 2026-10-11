-- Credit Card Customer Churn Analysis
-- File: sql/02_explore.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 4 — Explore
-- ============================================================
SELECT attrition_flag, COUNT(*) FROM raw_churn GROUP BY 1;                 -- how many left?
SELECT COUNT(*), COUNT(DISTINCT clientnum) FROM raw_churn;                  -- any duplicate customers?
SELECT education_level, COUNT(*) FROM raw_churn GROUP BY 1 ORDER BY 2 DESC; -- note 'Unknown'
SELECT income_category, COUNT(*) FROM raw_churn GROUP BY 1 ORDER BY 2 DESC;
SELECT card_category, COUNT(*) FROM raw_churn GROUP BY 1 ORDER BY 2 DESC;  -- note how few Platinum
SELECT MIN(total_trans_ct::int), MAX(total_trans_ct::int), MIN(customer_age::int), MAX(customer_age::int) FROM raw_churn;
