-- Credit Card Customer Churn Analysis
-- File: sql/01_load.sql
-- Step-by-step explanation: see README.md in this folder.


-- ============================================================
-- Day 3 — Load
-- ============================================================
CREATE TABLE raw_churn (
  clientnum TEXT, attrition_flag TEXT, customer_age TEXT, gender TEXT, dependent_count TEXT,
  education_level TEXT, marital_status TEXT, income_category TEXT, card_category TEXT,
  months_on_book TEXT, total_relationship_count TEXT, months_inactive_12_mon TEXT,
  contacts_count_12_mon TEXT, credit_limit TEXT, total_revolving_bal TEXT, avg_open_to_buy TEXT,
  total_amt_chng_q4_q1 TEXT, total_trans_amt TEXT, total_trans_ct TEXT, total_ct_chng_q4_q1 TEXT,
  avg_utilization_ratio TEXT, nb_1 TEXT, nb_2 TEXT);
