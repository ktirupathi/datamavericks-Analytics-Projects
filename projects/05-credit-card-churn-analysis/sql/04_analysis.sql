-- Credit Card Customer Churn Analysis
-- File: sql/04_analysis.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 6 — Q1: Who leaves?
-- ============================================================
SELECT ROUND(AVG(churned) * 100, 1) AS churn_pct, COUNT(*) AS customers FROM cust;

SELECT card_category, COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 2 DESC;
-- Repeat with income_category, age_band, gender


-- ============================================================
-- Day 7 — Q2: How do leavers use their card?
-- ============================================================
SELECT CASE WHEN churned = 1 THEN 'Left' ELSE 'Stayed' END AS status,
  COUNT(*) AS customers,
  ROUND(AVG(txn_count), 0)     AS avg_transactions,
  ROUND(AVG(txn_amount), 0)    AS avg_spend,
  ROUND(AVG(revolving_bal), 0) AS avg_revolving_bal,
  ROUND(AVG(utilisation), 2)   AS avg_utilisation
FROM cust GROUP BY 1;

SELECT txn_quintile, MIN(txn_count) AS from_txn, MAX(txn_count) AS to_txn,
       COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 1;


-- ============================================================
-- Day 8 — Q3: Do they go quiet first?
-- ============================================================
SELECT activity_change, COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 1;


-- ============================================================
-- Day 9 — Q4: Inactivity, contacts, products held
-- ============================================================
SELECT contacts, COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 1;
-- Repeat with months_inactive and products_held


-- ============================================================
-- Day 10 — Q5: Build and test the early-warning rule
-- ============================================================
SELECT
  CASE WHEN txn_count < 50 AND txn_count_change < 0.6 THEN 'Flagged' ELSE 'Not flagged' END AS rule,
  COUNT(*)      AS customers,
  SUM(churned)  AS leavers,
  ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1;

SELECT COUNT(*) FROM cust WHERE churned = 0 AND txn_count < 50 AND txn_count_change < 0.6;
