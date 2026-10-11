-- Credit Card Customer Churn Analysis
-- File: sql/03_clean_view.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 5 — Clean view with flags and bands
-- ============================================================
CREATE VIEW cust AS
SELECT
  clientnum,
  CASE WHEN attrition_flag = 'Attrited Customer' THEN 1 ELSE 0 END AS churned,
  customer_age::int AS age,
  CASE WHEN customer_age::int < 40 THEN 'Under 40' WHEN customer_age::int < 50 THEN '40-49'
       WHEN customer_age::int < 60 THEN '50-59' ELSE '60+' END AS age_band,
  gender, income_category, card_category,
  total_relationship_count::int AS products_held,
  months_inactive_12_mon::int    AS months_inactive,
  contacts_count_12_mon::int     AS contacts,
  total_trans_ct::int            AS txn_count,
  total_trans_amt::numeric       AS txn_amount,
  total_revolving_bal::numeric   AS revolving_bal,
  avg_utilization_ratio::numeric AS utilisation,
  total_ct_chng_q4_q1::numeric   AS txn_count_change,
  NTILE(5) OVER (ORDER BY total_trans_ct::int) AS txn_quintile,
  CASE WHEN total_ct_chng_q4_q1::numeric < 0.5  THEN '1. Activity halved or worse'
       WHEN total_ct_chng_q4_q1::numeric < 0.75 THEN '2. Activity down 25-50%'
       ELSE '3. Stable or up' END AS activity_change
FROM raw_churn;
