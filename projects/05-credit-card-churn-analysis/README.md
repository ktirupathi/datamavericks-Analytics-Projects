# Credit Card Customer Churn Analysis

You'll act as an analyst in a bank's credit card team. In 15 working days you'll find who is leaving, discover the warning signs in their card usage, and hand the retention team a simple rule and a call list. Banking is one of India's biggest analyst employers, so this project speaks directly to BFSI interviewers. Setup: the [Start here guide](../../START-HERE.md). Not on SQL yet? Every step has an Excel version.

> 📂 **Ready-made files in this folder:** [`sql/01_load.sql`](sql/01_load.sql), [`sql/02_explore.sql`](sql/02_explore.sql), [`sql/03_clean_view.sql`](sql/03_clean_view.sql), [`sql/04_analysis.sql`](sql/04_analysis.sql), [`powerbi/measures.dax`](powerbi/measures.dax). Use them to check your work — but type the queries yourself first; that's how you learn.

| Item | Detail |
| --- | --- |
| Project title | Credit Card Customer Churn Analysis |
| One line for interviews | "I found the early warning signs that credit card customers are about to leave, and built a simple rule to flag them." |
| Tools | PostgreSQL (or Excel) + Power BI |
| Data | \~10,000 anonymised credit card customers, one table, 23 columns |
| Time | 15 days × 1–2 hours |
| Skills you'll be able to claim | Churn analysis, CASE bands and NTILE, group comparisons, building and testing a rule (coverage and precision), DAX |

## The brief

> **From:** Sneha, Head of Cards Retention  
> **Subject:** Customers are leaving — can we see it coming?
>
> Hi — more customers are closing their credit cards, and by the time we notice, it's too late. Can you tell me who is leaving, what their behaviour looks like before they leave, and give us a simple way to flag at-risk customers so my team can call them first?

**Your 4 lines for the README:**

```
Stakeholder: Sneha, Head of Cards Retention
Decision:    Which customers the retention team calls, and what to offer
Questions:   Who leaves | usage differences | going quiet | relationship signals | early-warning rule
Success:     A tested rule with coverage and precision, and the size of today's call list
```

## Your 15-day plan

| Day | Task | Output |
| --- | --- | --- |
| 1 | Brief, folders, download | Folder ready |
| 2 | Meet the 23 columns | data\_notes.md |
| 3 | Load into PostgreSQL (or Excel table) | Row count checked |
| 4 | Explore: unknowns, ranges, junk columns | Issues listed |
| 5 | Clean view with flags and bands | cust view |
| 6 | Q1 — who leaves (demographics, card) | Insight 1 |
| 7 | Q2 — usage: leavers vs stayers | Insight 2 |
| 8 | Q3 — going quiet | Insight 3 |
| 9 | Q4 — inactivity, contacts, products | Insight 4 |
| 10 | Q5 — build and test the rule | Insight 5 + call list size |
| 11 | Power BI: load, measures | Model ready |
| 12 | Power BI: 3 pages | Dashboard |
| 13 | Story + one-page summary | Summary |
| 14 | README + GitHub | Published repo |
| 15 | LinkedIn + practise | Done |

## Week 1 — Get the data ready

### Day 1 — Brief and setup

1. Folder `credit-card-churn-analysis`.
2. Download [Credit Card Customers (Kaggle)](https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers) → unzip `BankChurners.csv` into `data/raw/`.
3. Paste the 4 README lines.

### Day 2 — Meet the data

One row is **one customer**. Group the columns in your notes:

| Group | Columns | Meaning |
| --- | --- | --- |
| ID and outcome | CLIENTNUM, Attrition\_Flag | "Attrited Customer" = left; "Existing Customer" = stayed |
| Who they are | Customer\_Age, Gender, Dependent\_count, Education\_Level, Marital\_Status, Income\_Category | Income is in bands like "$40K - $60K" |
| Their card | Card\_Category, Credit\_Limit, Months\_on\_book | Months\_on\_book = how long they've been a customer |
| Relationship | Total\_Relationship\_Count, Months\_Inactive\_12\_mon, Contacts\_Count\_12\_mon | Products held with the bank; months with no activity; times they contacted the bank |
| Usage (last 12 months) | Total\_Trans\_Amt, Total\_Trans\_Ct, Total\_Revolving\_Bal, Avg\_Utilization\_Ratio, Avg\_Open\_To\_Buy | Amount spent, number of transactions, balance carried, how much of the limit is used |
| Change | Total\_Amt\_Chng\_Q4\_Q1, Total\_Ct\_Chng\_Q4\_Q1 | Q4 activity ÷ Q1 activity: 1.0 = same, 0.5 = half as active |
| Junk | Two last columns starting with "Naive\_Bayes\_Classifier…" | Outputs from someone's model — they contain the answer, so using them is cheating |

**Banking words to know:** **churn/attrition** = customers leaving; **revolving balance** = money owed and carried to next month (banks earn interest on it); **utilisation** = balance ÷ credit limit.

### Day 3 — Load

**SQL path:** create database `card_churn`, then:

```sql
CREATE TABLE raw_churn (
  clientnum TEXT, attrition_flag TEXT, customer_age TEXT, gender TEXT, dependent_count TEXT,
  education_level TEXT, marital_status TEXT, income_category TEXT, card_category TEXT,
  months_on_book TEXT, total_relationship_count TEXT, months_inactive_12_mon TEXT,
  contacts_count_12_mon TEXT, credit_limit TEXT, total_revolving_bal TEXT, avg_open_to_buy TEXT,
  total_amt_chng_q4_q1 TEXT, total_trans_amt TEXT, total_trans_ct TEXT, total_ct_chng_q4_q1 TEXT,
  avg_utilization_ratio TEXT, nb_1 TEXT, nb_2 TEXT);
```

Import the CSV (Header on). `SELECT COUNT(*) FROM raw_churn;` should be just over 10,000.

**Excel path:** open the CSV, delete the last two columns, press Ctrl+T to make a Table named `Churn`.

### Day 4 — Explore

```sql
SELECT attrition_flag, COUNT(*) FROM raw_churn GROUP BY 1;                 -- how many left?
SELECT COUNT(*), COUNT(DISTINCT clientnum) FROM raw_churn;                  -- any duplicate customers?
SELECT education_level, COUNT(*) FROM raw_churn GROUP BY 1 ORDER BY 2 DESC; -- note 'Unknown'
SELECT income_category, COUNT(*) FROM raw_churn GROUP BY 1 ORDER BY 2 DESC;
SELECT card_category, COUNT(*) FROM raw_churn GROUP BY 1 ORDER BY 2 DESC;  -- note how few Platinum
SELECT MIN(total_trans_ct::int), MAX(total_trans_ct::int), MIN(customer_age::int), MAX(customer_age::int) FROM raw_churn;
```

(Excel: use a pivot with each column in Rows and Count of CLIENTNUM in Values.)

Write down: about 1 in 6 customers left; "Unknown" appears in education, marital status and income; Platinum and Gold groups are tiny — never trust a % from a tiny group.

**Decision on "Unknown":** keep these customers and treat "Unknown" as its own category. Removing them would throw away a meaningful share of the data.

### Day 5 — Clean view with flags and bands

```sql
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
```

**NTILE(5)** splits customers into 5 equal groups by transaction count: quintile 1 = least active 20%, quintile 5 = most active 20%. It's a standard way to compare "low vs high" without guessing cut-offs.

**Excel version:** add columns `Churned =IF([@Attrition_Flag]="Attrited Customer",1,0)`, `Activity Change =IF([@Total_Ct_Chng_Q4_Q1]<0.5,"1. Halved",IF([@Total_Ct_Chng_Q4_Q1]<0.75,"2. Down 25-50%","3. Stable or up"))`, and an age band with nested IFs. For quintiles use `=MATCH([@Total_Trans_Ct], {0;q1;q2;q3;q4})` where q1–q4 are from `=PERCENTILE.INC(Churn[Total_Trans_Ct], 0.2)`, `0.4`, `0.6`, `0.8`.

## Week 2 — Answer the questions

For every question the pattern is the same: group customers, count them, and calculate `AVG(churned)` — the share who left. In Excel: pivot with Average of Churned (as %) and Count of CLIENTNUM.

### Day 6 — Q1: Who leaves?

```sql
SELECT ROUND(AVG(churned) * 100, 1) AS churn_pct, COUNT(*) AS customers FROM cust;

SELECT card_category, COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 2 DESC;
-- Repeat with income_category, age_band, gender
```

**Read it honestly:** look at the spread. If churn only moves a few points across income, age and gender, that's the finding — demographics don't explain much. Insight: "\[X\]% of customers left; churn ranges only \[A\]–\[B\]% across income and age bands." (Or, if you see a big difference, report that.)

### Day 7 — Q2: How do leavers use their card?

```sql
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
```

Insight: "Leavers averaged \[X\] transactions a year vs \[Y\] for stayers. The least active fifth churns at \[A\]% vs \[B\]% for the most active."

### Day 8 — Q3: Do they go quiet first?

```sql
SELECT activity_change, COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 1;
```

This is the heart of the project. Customers whose transactions dropped sharply from Q1 to Q4 are telling the bank they're leaving, without saying a word. Insight: "Customers whose activity halved churn at \[X\]% vs \[Y\]% for stable customers."

### Day 9 — Q4: Inactivity, contacts, products held

```sql
SELECT contacts, COUNT(*) AS customers, ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1 ORDER BY 1;
-- Repeat with months_inactive and products_held
```

Read each one: does churn rise with more contacts (customers calling with problems)? Does it fall as products held go up (customers more tied to the bank)? Insights: "Customers who contacted the bank \[N\]+ times churn at \[X\]%"; "Single-product customers churn at \[A\]% vs \[B\]% for those with \[N\]+ products."

### Day 10 — Q5: Build and test the early-warning rule

Pick the 2 strongest signals from Days 7–9 (usually transaction count and the drop in activity). Try a rule:

```sql
SELECT
  CASE WHEN txn_count < 50 AND txn_count_change < 0.6 THEN 'Flagged' ELSE 'Not flagged' END AS rule,
  COUNT(*)      AS customers,
  SUM(churned)  AS leavers,
  ROUND(AVG(churned) * 100, 1) AS churn_pct
FROM cust GROUP BY 1;
```

Now calculate two numbers by hand from the result:

- **Coverage** = leavers who were flagged ÷ all leavers. "How many of the people who left would we have caught?"
- **Precision** = leavers who were flagged ÷ all flagged customers. "Of the people we'd call, how many were really leaving?"

Try 3 versions (change 50 to 40 or 60; 0.6 to 0.5 or 0.7) and record them in a small table:

| Rule | Flagged | Coverage | Precision |
| --- | --- | --- | --- |
| txn < 50 and change < 0.6 | \[N\] | \[X\]% | \[Y\]% |
| txn < 60 and change < 0.7 | \[N\] | \[X\]% | \[Y\]% |
| txn < 40 and change < 0.5 | \[N\] | \[X\]% | \[Y\]% |

Looser rules catch more leavers but call more people who weren't leaving. Pick the balance the retention team can handle. Finally, count how many **existing** customers your chosen rule flags — that's the call list:

```sql
SELECT COUNT(*) FROM cust WHERE churned = 0 AND txn_count < 50 AND txn_count_change < 0.6;
```

### Day 11 — Power BI: load and measures

Load the `cust` view (PostgreSQL connector) or your Excel table. Create a **What-if parameter** for the rule so Sneha can play with it: Modeling → New parameter → Numeric range → name `Txn Threshold`, 20 to 100, increment 5, default 50. Repeat for `Change Threshold`, 0.3 to 1.0, increment 0.05, default 0.6.

```
Customers = COUNTROWS ( Cust )
Leavers = SUM ( Cust[churned] )
Churn Rate = DIVIDE ( [Leavers], [Customers] )
Flagged = CALCULATE ( [Customers], FILTER ( Cust, Cust[txn_count] < [Txn Threshold Value] && Cust[txn_count_change] < [Change Threshold Value] ) )
Flagged Leavers = CALCULATE ( [Leavers], FILTER ( Cust, Cust[txn_count] < [Txn Threshold Value] && Cust[txn_count_change] < [Change Threshold Value] ) )
Coverage = DIVIDE ( [Flagged Leavers], [Leavers] )
Precision = DIVIDE ( [Flagged Leavers], [Flagged] )
Call List = [Flagged] - [Flagged Leavers]
```

(Power BI creates `[Txn Threshold Value]` and `[Change Threshold Value]` automatically with the parameters.)

### Day 12 — Power BI: build the 3 pages

**Page 1 — "1 in \[N\] customers leave — \[what you found about who they are\]"**: Cards (Customers, Leavers, Churn Rate); bar charts of Churn Rate by card\_category, income\_category and age\_band (show customer counts in tooltips).

**Page 2 — "They go quiet before they go" (hero page)**: Column chart of Churn Rate by txn\_quintile; column chart by activity\_change; bar charts by contacts and by products\_held; a scatter of txn\_count (X) vs txn\_amount (Y) with Legend = churned.

**Page 3 — "Who to call today"**: the two what-if slicers; Cards for Coverage, Precision and Call List; a table of flagged existing customers by CLIENTNUM, card and income (no personal names).

Save `dashboard/card_churn.pbix`, screenshot each page.

## Week 3 — Tell the story and publish

### Day 13 — The one-page summary

```
Credit Card Customer Churn Analysis

The question: Who is leaving, what do they do before they leave, and how can we flag them early?

What I found:
  1. [X]% of customers left. [Demographics explain little / Card type and income matter] — churn ranges [A]–[B]%.
  2. Behaviour explains a lot: the least active fifth churns at [C]% vs [D]% for the most active.
  3. Going quiet: customers whose activity halved from Q1 to Q4 churn at [E]%.
  4. More contacts with the bank and fewer products held are warning signs too.

What I recommend:
  1. Use the rule "fewer than [N] transactions and activity down [M]%": catches [F]% of leavers at [G]% precision.
  2. Call the [H] existing customers it flags today; offer spend-based rewards.
  3. Cross-sell a second product to single-product customers.
  4. Re-run monthly and test the calls: call half, compare churn after 3 months.

Limits: one snapshot in time; anonymised data; signals, not proven causes.
```

### Day 14 — README and GitHub

Repo `credit-card-churn-analysis`: README with the hero chart, sql/ (or the Excel workbook), .pbix, images, notes, summary.

### Day 15 — LinkedIn and practice

Post with the activity-change chart: "Your customers say goodbye months before they leave — if you know where to look." Practise the 60-second story.

## You're on track if…

- Your overall churn rate is around 1 in 6.
- Leavers show clearly fewer transactions than stayers.
- Your rule table shows the trade-off: when coverage goes up, precision goes down.

## Common mistakes I'd catch in a review

- Keeping the two Naive\_Bayes columns.
- Reporting only precision or only coverage.
- Trusting churn % for Platinum cards from a tiny group.
- Saying low transactions *cause* churn — they're a signal.

## Tell the story

### Your 60-second interview explanation

> "My project is a credit card customer churn analysis. A bank's retention head said customers were closing credit cards and the team found out too late. I analysed about 10,000 customers in SQL. \[Demographics didn't explain much\] — behaviour did. Customers who left had far fewer transactions, and their activity dropped sharply in the months before they left. More calls to the bank and fewer products were warning signs too. I turned the strongest signals into a simple rule, measured how many leavers it catches and how accurate it is, and built a Power BI page where the team can adjust the rule and see today's call list."

### Resume bullets

- "Credit Card Customer Churn Analysis: analysed \~10k credit card customers in SQL; customers whose transaction activity halved churned at \[X\]% vs \[Y\]% for stable customers."
- "Built an early-warning rule catching \[A\]% of leavers at \[B\]% precision, flagging \[N\] existing customers for retention calls; delivered a Power BI dashboard with what-if thresholds."

### Questions interviewers will ask

- "Why not machine learning?" — A rule is easy to explain and use; a model is the next step once the rule proves useful.
- "Coverage vs precision?" — Coverage: share of leavers caught. Precision: share of flagged customers who really leave.
- "How would you prove the calls work?" — Call a random half of flagged customers, compare churn after 3 months (A/B test).


---

← [Back to all projects](../../README.md) · [Start here guide](../../START-HERE.md)
