# E-commerce Delivery Performance & Customer Retention Analysis

You'll act as a junior analyst at an online marketplace. In 15 working days you'll go from a blank database to a dashboard and a recommendation the Head of Customer Experience could act on. Do the one-time setup in the [Start here guide](../../START-HERE.md) first.

> 📂 **Ready-made files in this folder:** [`sql/01_load.sql`](sql/01_load.sql), [`sql/02_explore.sql`](sql/02_explore.sql), [`sql/03_clean.sql`](sql/03_clean.sql), [`sql/04_build_order_facts.sql`](sql/04_build_order_facts.sql), [`sql/05_analysis.sql`](sql/05_analysis.sql), [`powerbi/measures.dax`](powerbi/measures.dax). Use them to check your work — but type the queries yourself first; that's how you learn.

| Item | Detail |
| --- | --- |
| Project title | E-commerce Delivery Performance & Customer Retention Analysis |
| One line for interviews | "I measured how much late deliveries hurt reviews and repeat purchases on a real marketplace, and where to fix delivery first." |
| Tools | PostgreSQL (pgAdmin) + Power BI |
| Data | Olist — real, anonymised Brazilian marketplace orders, 2016–2018, \~100k orders, 9 tables |
| Time | 15 days × 1–2 hours |
| Skills you'll be able to claim | Multi-table joins, date calculations, CASE, window functions (ROW\_NUMBER), data cleaning, Power BI modelling and DAX, business storytelling |

## The brief

> **From:** Priya, Head of Customer Experience  
> **Subject:** Are late deliveries hurting us?
>
> Hi — our review scores dropped and very few customers order again. Ops says delivery is fine; marketing says it isn't. Can you look at the order data and tell me how often we're late, how much it hurts reviews and repeat orders, and where we should fix first? A short readout by the end of the month would be great.

**Your 4 lines for the README:**

```
Stakeholder: Priya, Head of Customer Experience
Decision:    Whether to invest in fixing delivery, and where first
Questions:   Late rate | impact on reviews | repeat rate | impact of a late first order | where lateness happens
Success:     A clear yes/no on "is lateness hurting us", with the top 3 places to fix
```

## Your 15-day plan

| Day | Task | Output |
| --- | --- | --- |
| 1 | Read the brief, create folders, download data | Folder ready, README top lines |
| 2 | Look at every file, write data notes | data\_notes.md with grain of each table |
| 3 | Load 7 tables into PostgreSQL | Row counts match the CSVs |
| 4 | Run the 6 checks on each table | Issues listed in data notes |
| 5 | Build clean tables | Clean tables + cleaning log |
| 6 | Build the order\_facts table | One row per delivered order |
| 7 | Q1 — how often are we late? | Insight 1 |
| 8 | Q2 — how much does it hurt reviews? | Insight 2 |
| 9 | Q3 & Q4 — repeat customers | Insights 3 & 4 |
| 10 | Q5 — where does lateness happen? | Insight 5 |
| 11 | Power BI: load, model, measures | Model ready |
| 12 | Power BI: build 3 pages | Dashboard |
| 13 | Choose your story, write the one-page summary | Summary |
| 14 | README + GitHub | Published repo |
| 15 | LinkedIn post + practise the 60-second story | Live post, story practised |

## Week 1 — Get the data ready

### Day 1 — Brief and setup

1. Create the folder structure from the [Start here guide](../../START-HERE.md), named `ecommerce-delivery-analysis`.
2. Download the data: [Brazilian E-Commerce Public Dataset by Olist (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) → Download → unzip into `data/raw/`.
3. Paste the 4 README lines above into your README.

### Day 2 — Meet the data

Open each CSV in Excel (look only). You'll use 7 of the 9 files. Fill in your data notes like this:

| File | One row is… | Key | Links to | What to watch |
| --- | --- | --- | --- | --- |
| olist\_orders\_dataset.csv | One order | order\_id | customers (customer\_id) | Delivery date is blank for undelivered orders |
| olist\_customers\_dataset.csv | One customer **for one order** | customer\_id | orders | customer\_unique\_id is the real person |
| olist\_order\_items\_dataset.csv | One product line in an order | order\_id + order\_item\_id | orders, products, sellers | An order can have several items and sellers |
| olist\_order\_reviews\_dataset.csv | One review | review\_id | orders (order\_id) | Some orders have more than one review |
| olist\_products\_dataset.csv | One product | product\_id | items | Category names in Portuguese; some column names misspelt ("lenght") in the source |
| olist\_sellers\_dataset.csv | One seller | seller\_id | items | — |
| product\_category\_name\_translation.csv | One category | product\_category\_name | products | English names |

**The most important thing you'll learn today:** `customer_id` is created fresh for every order. The same person ordering twice has two different customer\_ids but the same `customer_unique_id`. Write this in big letters in your notes.

### Day 3 — Load into PostgreSQL

Create a database called `ecommerce_delivery` in pgAdmin. Open the Query Tool and run this script (save it as `sql/01_load.sql`). Every column is TEXT to make the import painless.

```sql
CREATE TABLE raw_orders (
  order_id TEXT, customer_id TEXT, order_status TEXT, order_purchase_timestamp TEXT,
  order_approved_at TEXT, order_delivered_carrier_date TEXT,
  order_delivered_customer_date TEXT, order_estimated_delivery_date TEXT);

CREATE TABLE raw_customers (
  customer_id TEXT, customer_unique_id TEXT, customer_zip_code_prefix TEXT,
  customer_city TEXT, customer_state TEXT);

CREATE TABLE raw_order_items (
  order_id TEXT, order_item_id TEXT, product_id TEXT, seller_id TEXT,
  shipping_limit_date TEXT, price TEXT, freight_value TEXT);

CREATE TABLE raw_reviews (
  review_id TEXT, order_id TEXT, review_score TEXT, review_comment_title TEXT,
  review_comment_message TEXT, review_creation_date TEXT, review_answer_timestamp TEXT);

CREATE TABLE raw_products (
  product_id TEXT, product_category_name TEXT, product_name_lenght TEXT,
  product_description_lenght TEXT, product_photos_qty TEXT, product_weight_g TEXT,
  product_length_cm TEXT, product_height_cm TEXT, product_width_cm TEXT);

CREATE TABLE raw_sellers (
  seller_id TEXT, seller_zip_code_prefix TEXT, seller_city TEXT, seller_state TEXT);

CREATE TABLE raw_category_translation (
  product_category_name TEXT, product_category_name_english TEXT);
```

Then import each CSV into its table (right-click table → Import/Export Data → Import → Header on). The reviews file has comments containing commas and line breaks — that's fine because they're inside quotes; leave the Quote character as `"`.

Check each load:

```sql
SELECT 'orders' AS t, COUNT(*) FROM raw_orders
UNION ALL SELECT 'customers', COUNT(*) FROM raw_customers
UNION ALL SELECT 'items', COUNT(*) FROM raw_order_items
UNION ALL SELECT 'reviews', COUNT(*) FROM raw_reviews
UNION ALL SELECT 'products', COUNT(*) FROM raw_products
UNION ALL SELECT 'sellers', COUNT(*) FROM raw_sellers
UNION ALL SELECT 'translation', COUNT(*) FROM raw_category_translation;
```

Compare with the row counts Excel showed (Excel shows the last row number; subtract 1 for the header). Orders should be just under 100,000.

### Day 4 — Explore (the 6 checks)

Run these and write down what you find. Save as `sql/02_explore.sql`.

```sql
-- Is order_id unique?  (expect rows = unique)
SELECT COUNT(*) AS rows, COUNT(DISTINCT order_id) AS unique_orders FROM raw_orders;

-- What statuses exist?
SELECT order_status, COUNT(*) FROM raw_orders GROUP BY 1 ORDER BY 2 DESC;

-- How many orders have no delivery date, by status?
SELECT order_status, COUNT(*) FROM raw_orders
WHERE order_delivered_customer_date IS NULL OR order_delivered_customer_date = ''
GROUP BY 1 ORDER BY 2 DESC;

-- Real people vs order-level customer ids
SELECT COUNT(DISTINCT customer_id) AS customer_ids, COUNT(DISTINCT customer_unique_id) AS real_customers
FROM raw_customers;

-- Orders with more than one review
SELECT COUNT(*) FROM (SELECT order_id FROM raw_reviews GROUP BY order_id HAVING COUNT(*) > 1) t;

-- Date range
SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) FROM raw_orders;
```

**What you should notice:** almost all orders are "delivered"; real customers are fewer than customer\_ids; a few hundred orders have multiple reviews; the first and last few months have very few orders (the data starts and ends with thin periods — you'll exclude them from trends).

### Day 5 — Clean

Save as `sql/03_clean.sql`. Each block below fixes one thing.

```sql
-- Orders: proper timestamps
CREATE TABLE orders AS
SELECT order_id, customer_id, order_status,
  NULLIF(order_purchase_timestamp, '')::timestamp      AS purchase_ts,
  NULLIF(order_delivered_customer_date, '')::timestamp AS delivered_ts,
  NULLIF(order_estimated_delivery_date, '')::timestamp AS estimated_ts
FROM raw_orders;

-- Customers: unchanged, just typed
CREATE TABLE customers AS
SELECT customer_id, customer_unique_id, customer_city, customer_state FROM raw_customers;

-- Reviews: keep ONE review per order (the latest)
CREATE TABLE reviews AS
SELECT order_id, review_score::int AS review_score
FROM (
  SELECT order_id, review_score, review_creation_date,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date DESC) AS rn
  FROM raw_reviews) t
WHERE rn = 1;

-- Items with numbers
CREATE TABLE order_items AS
SELECT order_id, order_item_id::int AS item_no, product_id, seller_id,
       price::numeric AS price, freight_value::numeric AS freight
FROM raw_order_items;

-- Products with English category
CREATE TABLE products AS
SELECT p.product_id,
       COALESCE(t.product_category_name_english, p.product_category_name, 'unknown') AS category
FROM raw_products p
LEFT JOIN raw_category_translation t ON t.product_category_name = p.product_category_name;

CREATE TABLE sellers AS SELECT seller_id, seller_state FROM raw_sellers;
```

**How the review de-duplication works:** `ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_creation_date DESC)` numbers the reviews within each order, newest first. Keeping `rn = 1` keeps exactly one review per order. This is one of the most-asked SQL interview patterns — you now have a real example of using it.

Add to your cleaning log: "Kept the latest review per order — removed \[N\] duplicate reviews."

## Week 2 — Answer the questions

### Day 6 — Build one analysis table: order\_facts

Instead of joining 4 tables in every query, build one table with one row per delivered order and everything you need.

```sql
CREATE TABLE order_facts AS
SELECT
  o.order_id,
  c.customer_unique_id,
  c.customer_state,
  o.purchase_ts::date                                AS purchase_date,
  DATE_TRUNC('month', o.purchase_ts)::date           AS purchase_month,
  (o.delivered_ts::date - o.estimated_ts::date)      AS days_late,
  CASE WHEN o.delivered_ts::date > o.estimated_ts::date THEN 1 ELSE 0 END AS is_late,
  (o.delivered_ts::date - o.purchase_ts::date)       AS delivery_days,
  r.review_score
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_ts IS NOT NULL;
```

**Line by line:** `days_late` is delivered date minus promised date — positive means late, zero or negative means on time. `is_late` turns that into a 1/0 flag, so `AVG(is_late)` later gives the late %. `LEFT JOIN reviews` keeps orders even if they have no review. The `WHERE` keeps only delivered orders, because you can't be late for an order that never arrived.

**Check:** `SELECT COUNT(*), COUNT(DISTINCT order_id) FROM order_facts;` — both numbers must be equal. If not, a join created duplicates.

### Day 7 — Q1: How often are we late?

```sql
SELECT ROUND(AVG(is_late) * 100, 1) AS late_pct, COUNT(*) AS delivered_orders FROM order_facts;

SELECT purchase_month, COUNT(*) AS orders, ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM order_facts
GROUP BY 1 HAVING COUNT(*) >= 500   -- skip thin months at the start and end
ORDER BY 1;
```

**Read the result:** is the late % stable, or are there months where it jumps? Spikes often line up with sales peaks (like November). Write the insight: "\[X\]% of delivered orders arrive late; it peaked at \[Y\]% in \[month\]."

### Day 8 — Q2: How much does lateness hurt reviews?

```sql
SELECT
  CASE WHEN days_late <= 0 THEN '1. On time or early'
       WHEN days_late <= 3 THEN '2. 1–3 days late'
       WHEN days_late <= 7 THEN '3. 4–7 days late'
       ELSE '4. 8+ days late' END                         AS delivery_bucket,
  COUNT(*)                                                AS orders,
  ROUND(AVG(review_score), 2)                             AS avg_review,
  ROUND(AVG(CASE WHEN review_score <= 2 THEN 1 ELSE 0 END) * 100, 1) AS bad_review_pct
FROM order_facts
WHERE review_score IS NOT NULL
GROUP BY 1 ORDER BY 1;
```

The numbers in the bucket names ("1.", "2."…) make them sort in order — a small trick that saves time in Power BI too.

**Read the result:** you're looking for a staircase — each later bucket should have a lower average review and a higher bad-review %. That staircase is your hero chart. Insight: "On-time orders average \[X\] stars; 8+ days late average \[Y\], and \[Z\]% of them are 1–2 star reviews."

### Day 9 — Q3 & Q4: Do customers come back?

```sql
-- Q3. What % of real customers ever ordered again?
SELECT COUNT(*) AS customers,
       SUM(CASE WHEN orders > 1 THEN 1 ELSE 0 END) AS repeat_customers,
       ROUND(AVG(CASE WHEN orders > 1 THEN 1 ELSE 0 END) * 100, 2) AS repeat_pct
FROM (SELECT customer_unique_id, COUNT(*) AS orders FROM order_facts GROUP BY 1) t;

-- Q4. Does a late FIRST order reduce coming back?
WITH ranked AS (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY customer_unique_id ORDER BY purchase_date) AS order_no,
    COUNT(*)     OVER (PARTITION BY customer_unique_id)                         AS total_orders
  FROM order_facts)
SELECT
  CASE WHEN is_late = 1 THEN 'First order late' ELSE 'First order on time' END AS first_experience,
  COUNT(*) AS customers,
  ROUND(AVG(CASE WHEN total_orders > 1 THEN 1 ELSE 0 END) * 100, 2) AS came_back_pct
FROM ranked
WHERE order_no = 1
GROUP BY 1;
```

**How Q4 works:** `ROW_NUMBER()` finds each customer's first order; `COUNT(*) OVER` counts all their orders without collapsing rows. Then we compare the come-back rate for people whose first order was late vs on time.

**Read the result:** the repeat % will be small — that's a finding in itself (most marketplace customers buy once). Then compare the two groups. Be honest: if the difference is small, say so. Insight: "Only \[X\]% of customers ever reorder; it's \[A\]% if their first order was on time vs \[B\]% if it was late."

### Day 10 — Q5: Where does lateness happen?

```sql
-- By customer state
SELECT customer_state, COUNT(*) AS orders, ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM order_facts GROUP BY 1 HAVING COUNT(*) >= 300 ORDER BY late_pct DESC;

-- By product category (an order can have several categories; count each order-category pair once)
SELECT p.category, COUNT(DISTINCT f.order_id) AS orders, ROUND(AVG(f.is_late) * 100, 1) AS late_pct
FROM order_facts f
JOIN order_items i ON i.order_id = f.order_id
JOIN products p    ON p.product_id = i.product_id
GROUP BY 1 HAVING COUNT(DISTINCT f.order_id) >= 300 ORDER BY late_pct DESC;

-- Seller state → customer state routes
SELECT s.seller_state, f.customer_state, COUNT(DISTINCT f.order_id) AS orders,
       ROUND(AVG(f.is_late) * 100, 1) AS late_pct
FROM order_facts f
JOIN order_items i ON i.order_id = f.order_id
JOIN sellers s     ON s.seller_id = i.seller_id
GROUP BY 1, 2 HAVING COUNT(DISTINCT f.order_id) >= 300 ORDER BY late_pct DESC LIMIT 15;
```

`HAVING COUNT(*) >= 300` hides small groups whose percentages would be unreliable. Mention this rule in your interview — it shows judgement.

Insight: "Late deliveries concentrate in \[states\] and on \[seller → customer routes\]; \[category\] has the highest late rate."

Export these result tables to `data/clean/` as CSVs (pgAdmin results grid → download icon) — you'll use them in Power BI.

### Day 11 — Power BI: load, model, measures

1. Power BI Desktop → Home → **Get data** → PostgreSQL database → Server `localhost`, Database `ecommerce_delivery` → select `order_facts` → **Load**. (Or Text/CSV if you exported it.)
2. Also load your Q5 CSV exports (late % by state and category).
3. Create a **Delivery Bucket** column: Table view → select order\_facts → New column:

```
Delivery Bucket =
SWITCH ( TRUE (),
    order_facts[days_late] <= 0, "1. On time",
    order_facts[days_late] <= 3, "2. 1–3 days late",
    order_facts[days_late] <= 7, "3. 4–7 days late",
    "4. 8+ days late" )
```

4. Create measures (right-click order\_facts → New measure, one at a time):

```
Orders = COUNTROWS ( order_facts )
Late % = AVERAGE ( order_facts[is_late] )
Avg Review = AVERAGE ( order_facts[review_score] )
Bad Review % = DIVIDE ( CALCULATE ( [Orders], order_facts[review_score] <= 2 ), CALCULATE ( [Orders], NOT ISBLANK ( order_facts[review_score] ) ) )
Avg Delivery Days = AVERAGE ( order_facts[delivery_days] )
```

5. Select each % measure → Measure tools → Format: Percentage, 1 decimal.

### Day 12 — Power BI: build the 3 pages

**Page 1 — "\[X\]% of orders arrive late"**

1. Insert 4 **Card** visuals across the top: Orders, Late %, Avg Review, Avg Delivery Days.
2. Insert a **Line chart**: X-axis = purchase\_month, Y-axis = Late %. Filter out the thin first/last months (Filters pane → purchase\_month → uncheck them).
3. Insert a **Slicer** with customer\_state.
4. Title the page with your finding, using a Text box.

**Page 2 — "The later the order, the worse the review" (your hero page)**

1. **Clustered column chart:** X-axis = Delivery Bucket, Y-axis = Avg Review. Turn on Data labels. Colour the "On time" bar grey and the late bars in one strong colour (Format → Columns → colour by category).
2. Second **Clustered column chart:** X = Delivery Bucket, Y = Bad Review %.
3. **Card** with the repeat-customer % and a text box comparing first-order late vs on time.

**Page 3 — "Where to fix first"**

1. **Bar chart** from the state export: customer\_state on the Y-axis, late\_pct as value, sorted descending.
2. **Table** of the top 10 seller → customer routes with orders and late %. Add conditional formatting: Late % column → Cell elements → Background colour.
3. **Bar chart** of late % by category (top 10).
4. A **Text box** with your 3 recommendations.

Save as `dashboard/ecommerce_delivery.pbix`, then screenshot each page into `images/`.

## Week 3 — Tell the story and publish

### Day 13 — Choose the story and write the summary

Open your insight log and pick the 3 insights that answer Priya's question best — usually: how often we're late, how much it hurts reviews, and where to fix. Then write the one-page summary:

```
E-commerce Delivery Performance & Customer Retention Analysis

The question: Are late deliveries hurting reviews and repeat orders, and where should we fix first?

What I found:
  1. [X]% of delivered orders arrive after the promised date.
  2. Late orders average [Y] stars vs [Z] on time; at 8+ days late, [W]% of reviews are 1–2 stars.
  3. Only [A]% of customers reorder; [B]% if their first order was late vs [C]% if on time.

Where it happens: [states / routes / categories] account for [P]% of late orders.

What I recommend:
  1. Fix delivery on the [top 3 routes/states] first.
  2. Set more realistic delivery promises for [categories] — a later honest date beats a missed one.
  3. Send an apology + voucher automatically when an order is 3+ days late.

Limits: correlation not proof of cause; product quality also affects reviews; data is 2016–2018.
Next: read 1–2 star review comments to confirm delivery is the reason; measure lost revenue.
```

### Day 14 — README and GitHub

Fill in the README template from the [Start here guide](../../START-HERE.md). Put the hero chart (Page 2) at the top. Upload the `sql/` folder, the `.pbix`, `images/`, `data_notes.md`, the one-page summary and README to a new GitHub repo named `ecommerce-delivery-analysis`. Don't upload the raw CSVs — link to Kaggle instead.

### Day 15 — LinkedIn and practice

Post the LinkedIn version, then practise the 60-second story out loud until you can say it without notes.

## You're on track if…

- `order_facts` has one row per delivered order (COUNT = COUNT DISTINCT order\_id).
- Your delivery buckets show a clear staircase in average review.
- Your repeat-customer % is small. If it's above 30%, you counted customer\_id instead of customer\_unique\_id.

## Common mistakes I'd catch in a review

- Counting repeat customers with customer\_id (every order looks like a new person).
- Averaging reviews without removing duplicate reviews.
- Including cancelled orders in the late rate.
- Reporting late % for a state with 40 orders as if it were reliable.
- A dashboard titled "Olist Dashboard" instead of a finding.

## Tell the story

### Your 60-second interview explanation

> "My project is an e-commerce delivery performance and customer retention analysis. A marketplace's customer experience head wanted to know if late deliveries were hurting reviews and repeat orders. I used about 100,000 real orders across six tables in PostgreSQL. The tricky parts were that each order had a new customer ID, so I used the unique customer ID to find repeat buyers, and some orders had duplicate reviews, which I removed with ROW\_NUMBER. I found that late orders got much worse reviews — the later, the worse — and very few customers ever came back. Lateness was concentrated in a few states and routes, so I recommended fixing those first and setting more realistic delivery dates. I built the dashboard in Power BI."

### Resume bullets

- "E-commerce Delivery Performance Analysis: joined 6 tables (\~100k orders) in PostgreSQL to link delivery performance to reviews and repeat purchases; late orders averaged \[X\] stars vs \[Y\] on time."
- "Identified \[N\] states/routes driving \[P\]% of late deliveries; built a 3-page Power BI dashboard and recommended targeted fixes and a late-order recovery voucher."

### Questions interviewers will ask

- "Why customer\_unique\_id?" — customer\_id is created per order; unique\_id identifies the person.
- "How did you handle duplicate reviews?" — ROW\_NUMBER partitioned by order, kept the latest.
- "Is lateness the cause of bad reviews?" — Strongly linked, not proven; I'd confirm by reading low-score comments.
- "What would you do next?" — Seller-level analysis and estimating revenue lost from customers who didn't return.


---

← [Back to all projects](../../README.md) · [Start here guide](../../START-HERE.md)
