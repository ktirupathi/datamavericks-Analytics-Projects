# Marketing Channel Attribution & Conversion Funnel Analysis

You'll act as the marketing analyst at a growing online toy store. In 15 working days you'll build marketing channels from raw tracking data, follow visitors from first page to order, and give the marketing director a budget recommendation with an actual bidding number. Setup: the [Start here guide](../../START-HERE.md) (PostgreSQL + Power BI).

> 📂 **Ready-made files in this folder:** [`sql/01_load.sql`](sql/01_load.sql), [`sql/02_explore.sql`](sql/02_explore.sql), [`sql/03_clean_and_channels.sql`](sql/03_clean_and_channels.sql), [`sql/04_analysis.sql`](sql/04_analysis.sql), [`sql/05_export_for_powerbi.sql`](sql/05_export_for_powerbi.sql), [`powerbi/measures.dax`](powerbi/measures.dax). Use them to check your work — but type the queries yourself first; that's how you learn.

| Item | Detail |
| --- | --- |
| Project title | Marketing Channel Attribution & Conversion Funnel Analysis |
| One line for interviews | "I worked out which marketing channels bring paying customers and the most a company can afford to pay per ad click." |
| Tools | PostgreSQL + Power BI |
| Data | Maven Analytics Toy Store E-Commerce Database ("Maven Fuzzy Factory") — 6 tables, \~470k website sessions, \~32k orders, 2012–2015 (fictitious store, realistic web-analytics structure) |
| Time | 15 days × 1–2 hours |
| Skills you'll be able to claim | CASE-based channel grouping, LEFT JOINs, conversion metrics, page-level funnels, revenue and margin per session, Power BI |

## The brief

> **From:** Meera, Marketing Director  
> **Subject:** Where should next year's budget go?
>
> Hi — we've grown a lot in 3 years and I'm planning next year's budget. I need to know which channels actually bring orders (not just visits), whether mobile is worth investing in, where people drop off on the website, and how much we can afford to bid for paid search clicks. Can you pull this together for our planning meeting?

**Your 4 lines for the README:**

```
Stakeholder: Meera, Marketing Director
Decision:    Budget split across channels and devices; bid limits for paid search; which page to fix
Questions:   Growth | channel quality | device | website funnel | max affordable bid
Success:     Channel ranking on value (not traffic), one page to fix, and a $ bid ceiling per device
```

## Your 15-day plan

| Day | Task | Output |
| --- | --- | --- |
| 1 | Brief, folders, download | Folder ready |
| 2 | Meet the 6 tables | data\_notes.md |
| 3 | Load into PostgreSQL | Row counts checked |
| 4 | Explore: tracking values, pages, dates | Issues listed |
| 5 | Clean tables + channel grouping | sessions\_ch view |
| 6 | Q1 — growth | Insight 1 |
| 7 | Q2 — channels | Insights 2–3 |
| 8 | Q3 — devices | Insight 4 |
| 9 | Q4 — website funnel | Insight 5 |
| 10 | Q5 — max affordable bid | Insight 6 |
| 11 | Export + Power BI model | Model ready |
| 12 | Power BI: 4 pages | Dashboard |
| 13 | Story + one-page summary | Summary |
| 14 | README + GitHub | Published repo |
| 15 | LinkedIn + practise | Done |

## Week 1 — Get the data ready

### Day 1 — Brief and setup

1. Folder `marketing-funnel-analysis`.
2. Download from [Toy Store E-Commerce Database (Maven Analytics Data Playground)](https://mavenanalytics.io/data-playground/toy-store-e-commerce-database) → unzip into `data/raw/`.
3. Paste the 4 README lines.

### Day 2 — Meet the data

| Table | One row is… | Key | Links |
| --- | --- | --- | --- |
| website\_sessions | One visit to the website | website\_session\_id | orders, pageviews |
| website\_pageviews | One page viewed during a visit | website\_pageview\_id | sessions |
| orders | One order | order\_id | sessions (website\_session\_id) |
| order\_items | One product in an order | order\_item\_id | orders, products |
| order\_item\_refunds | One refunded item | order\_item\_refund\_id | order\_items |
| products | One product | product\_id | order\_items |

**Marketing words you need (write these in your notes):**

- **Session** — one visit. **Conversion rate** — orders ÷ sessions.
- **utm\_source / utm\_campaign** — tags added to ad links so the company knows where a visitor came from. gsearch = Google search ads, bsearch = Bing ads, socialbook = a social media ad; nonbrand = ads for generic searches ("teddy bear"), brand = ads for people searching the company's name.
- **http\_referer** — the website the visitor came from. If there's no utm tag but there is a referer, the visitor clicked a free (organic) search result. No tag and no referer = they typed the address directly (direct type-in).

### Day 3 — Load into PostgreSQL

Create database `marketing_funnel`. Create TEXT tables, copying column names from each CSV's header row in the same order (check — they should be similar to below), then import each file with Header on.

```sql
CREATE TABLE raw_sessions (website_session_id TEXT, created_at TEXT, user_id TEXT, is_repeat_session TEXT,
  utm_source TEXT, utm_campaign TEXT, utm_content TEXT, device_type TEXT, http_referer TEXT);
CREATE TABLE raw_pageviews (website_pageview_id TEXT, created_at TEXT, website_session_id TEXT, pageview_url TEXT);
CREATE TABLE raw_orders (order_id TEXT, created_at TEXT, website_session_id TEXT, user_id TEXT,
  primary_product_id TEXT, items_purchased TEXT, price_usd TEXT, cogs_usd TEXT);
CREATE TABLE raw_order_items (order_item_id TEXT, created_at TEXT, order_id TEXT, product_id TEXT,
  is_primary_item TEXT, price_usd TEXT, cogs_usd TEXT);
CREATE TABLE raw_refunds (order_item_refund_id TEXT, created_at TEXT, order_item_id TEXT, order_id TEXT, refund_amount_usd TEXT);
CREATE TABLE raw_products (product_id TEXT, created_at TEXT, product_name TEXT);
```

The pageviews file is the biggest (over a million rows) — importing takes a minute. Check counts with `SELECT COUNT(*)` on each table.

### Day 4 — Explore

```sql
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
```

Write down the list of page URLs. You'll see a home page, landing pages, a products page, one page per product, /cart, /shipping, billing page(s), and a thank-you page. Note whether empty tracking values appear as blank or as the word NULL.

### Day 5 — Clean and build the channel view

```sql
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
```

**Why `NULLIF(NULLIF(x, ''), 'NULL')`:** it turns both empty text and the word "NULL" into a real NULL, so `IS NULL` works in the CASE. **Why LEFT JOIN:** it keeps every visit; order columns are filled only for visits that bought. That's what lets you calculate conversion.

Check: `SELECT channel, COUNT(*) FROM sessions_ch GROUP BY 1;` — "Other" should be small. If it's big, look at what's in it and adjust the CASE.

## Week 2 — Answer the questions

### Day 6 — Q1: How have we grown?

```sql
SELECT DATE_TRUNC('quarter', created_at)::date AS quarter,
  COUNT(*) AS sessions, COUNT(order_id) AS orders,
  ROUND(COUNT(order_id) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(SUM(revenue), 0) AS revenue,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions_ch GROUP BY 1 ORDER BY 1;
```

`COUNT(order_id)` counts only non-null values — i.e. sessions that ordered. The last quarter may be incomplete; label it. Insight: "Sessions grew \[X\]× and orders \[Y\]×; conversion rose from \[A\]% to \[B\]%."

### Day 7 — Q2: Which channels pay?

```sql
SELECT channel,
  COUNT(*) AS sessions,
  ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS share_of_sessions_pct,
  COUNT(order_id) AS orders,
  ROUND(COUNT(order_id) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions_ch GROUP BY 1 ORDER BY sessions DESC;

-- "Free" traffic over time: organic + direct + brand as a share of all sessions
SELECT DATE_TRUNC('quarter', created_at)::date AS quarter,
  ROUND(AVG(CASE WHEN channel IN ('Organic search','Direct type-in','Paid search – brand') THEN 1 ELSE 0 END) * 100, 1) AS brand_driven_pct
FROM sessions_ch GROUP BY 1 ORDER BY 1;
```

`SUM(COUNT(*)) OVER ()` is a window function that totals all groups — so you get each channel's share without a second query.

Insights: "\[Channel\] brings \[X\]% of visits but converts at \[Y\]%; \[channel\] converts best." and "Brand-driven traffic rose from \[A\]% to \[B\]% — the business depends less on paid ads over time." (Brand paid search counts as brand-driven because those people were already searching for the company.)

### Day 8 — Q3: Desktop vs mobile

```sql
SELECT channel, device_type, COUNT(*) AS sessions,
  ROUND(COUNT(order_id) * 100.0 / COUNT(*), 2) AS conv_rate_pct,
  ROUND(SUM(revenue) / COUNT(*), 2) AS revenue_per_session
FROM sessions_ch
WHERE channel IN ('Paid search – nonbrand', 'Organic search', 'Direct type-in')
GROUP BY 1, 2 ORDER BY 1, 2;
```

Insight: "Mobile converts at \[X\]% vs \[Y\]% on desktop — each mobile visit is worth $\[Z\] less."

### Day 9 — Q4: Where do visitors drop off?

```sql
WITH steps AS (
  SELECT session_id,
    MAX(CASE WHEN pageview_url = '/products' THEN 1 ELSE 0 END)                  AS s1_products,
    MAX(CASE WHEN pageview_url LIKE '/the-%' THEN 1 ELSE 0 END)                   AS s2_product_page,
    MAX(CASE WHEN pageview_url = '/cart' THEN 1 ELSE 0 END)                      AS s3_cart,
    MAX(CASE WHEN pageview_url = '/shipping' THEN 1 ELSE 0 END)                  AS s4_shipping,
    MAX(CASE WHEN pageview_url LIKE '/billing%' THEN 1 ELSE 0 END)               AS s5_billing,
    MAX(CASE WHEN pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END)  AS s6_ordered
  FROM pageviews GROUP BY session_id)
SELECT COUNT(*) AS sessions,
  SUM(s1_products) AS products, SUM(s2_product_page) AS product_page, SUM(s3_cart) AS cart,
  SUM(s4_shipping) AS shipping, SUM(s5_billing) AS billing, SUM(s6_ordered) AS ordered
FROM steps;
```

Adjust the page names to match your Day 4 list (product pages start with "/the-" in this store — confirm it). Then calculate each step ÷ the step before it in Excel or Power BI.

**How it works:** for each session, `MAX(CASE …)` gives 1 if the visitor ever saw that page. Summing across sessions gives how many reached each step.

Insight: "The biggest drop is between \[step\] and \[step\] — only \[X\]% continue." Bonus: if there are two billing pages (`/billing` and `/billing-2`), the company tested a new version — compare the order rate of sessions that saw each.

### Day 10 — Q5: The maximum affordable bid

```sql
SELECT device_type, COUNT(*) AS sessions,
  ROUND((SUM(revenue) - SUM(cogs)) / COUNT(*), 2) AS margin_per_session
FROM sessions_ch
WHERE channel = 'Paid search – nonbrand'
GROUP BY 1;
```

**What this means:** margin per session is how much profit (before ad cost) the average paid-search visit makes. If Google charges more than this per click, each visit loses money. So this number is the **ceiling** for the bid. Use the most recent 12 months for a fairer current number (add a date filter).

Insight: "A paid nonbrand visit earns $\[X\] margin on desktop and $\[Y\] on mobile — bids above these lose money."

## Week 2 continued — Dashboard

### Day 11 — Export and model

Create a daily summary for Power BI and export it to `data/clean/daily.csv`:

```sql
SELECT created_at::date AS day, channel, device_type,
  COUNT(*) AS sessions, COUNT(order_id) AS orders,
  COALESCE(SUM(revenue), 0) AS revenue, COALESCE(SUM(cogs), 0) AS cogs
FROM sessions_ch GROUP BY 1, 2, 3;
```

Also export your funnel result as `funnel.csv` (one row per step with a step number, step name and sessions). In Power BI, load both, then New measure:

```
Sessions = SUM ( Daily[sessions] )
Orders = SUM ( Daily[orders] )
Conversion Rate = DIVIDE ( [Orders], [Sessions] )
Revenue = SUM ( Daily[revenue] )
Revenue per Session = DIVIDE ( [Revenue], [Sessions] )
Margin per Session = DIVIDE ( [Revenue] - SUM ( Daily[cogs] ), [Sessions] )
```

### Day 12 — Power BI: build the 4 pages

**Page 1 — "Orders grew \[X\]× in 3 years"**: Cards (Sessions, Orders, Conversion Rate, Revenue); Line chart of Sessions and Orders by quarter (day → date hierarchy → Quarter); Line of Conversion Rate.

**Page 2 — "Not all traffic is equal" (hero page)**: **Stacked area chart** of Sessions by channel over time; **Table** of channel with Sessions, Conversion Rate, Revenue per Session, conditional formatting on the last two.

**Page 3 — "What a visit is worth"**: Clustered column of Conversion Rate by device\_type, Legend = channel; Cards with Margin per Session filtered to Paid search – nonbrand for desktop and for mobile (visual-level filters) — label them "Max bid".

**Page 4 — "Where visitors leave"**: **Funnel** visual from funnel.csv (Category = step name, Values = sessions), sorted by step number; a text box naming the worst step.

Save `dashboard/marketing_funnel.pbix`, screenshot each page.

## Week 3 — Tell the story and publish

### Day 13 — The one-page summary

```
Marketing Channel Attribution & Conversion Funnel Analysis

The question: Which channels bring paying customers, is mobile worth it, where do visitors drop off, and what can we bid?

What I found:
  1. Sessions grew [X]× and orders [Y]× in 3 years; conversion rose from [A]% to [B]%.
  2. Paid nonbrand search brings [C]% of visits, but brand-driven traffic grew to [D]% and converts at [E]%.
  3. Mobile converts at [F]% vs [G]% on desktop.
  4. The biggest drop-off is [step] → [step]: only [H]% continue.

What I recommend:
  1. Cap paid nonbrand bids at $[X] (desktop) and $[Y] (mobile).
  2. Fix the [step] page first; test the change before rolling out.
  3. Keep investing in brand — it's becoming the most valuable traffic.

Limits: no ad-spend data, so no ROI; fictitious store; funnel checks pages viewed, not strict order.
```

### Day 14 — README and GitHub

Repo `marketing-funnel-analysis`: README, sql/ folder (load, clean, analysis), .pbix, images, notes, summary.

### Day 15 — LinkedIn and practice

Post with the channel table: "More traffic isn't more money." Practise the 60-second story.

## You're on track if…

- Your overall conversion rate is a few percent, not 30% or 100%.
- "Paid search – nonbrand" is the largest channel, especially early on.
- "Other" in your channel grouping is tiny.

## Common mistakes I'd catch in a review

- INNER JOIN between sessions and orders (conversion becomes 100%).
- Treating the text "NULL" as a real value, so organic and direct are miscounted.
- Ranking channels by sessions instead of conversion and revenue per session.
- Showing an incomplete last quarter as a drop.

## Tell the story

### Your 60-second interview explanation

> "My project is a marketing channel attribution and conversion funnel analysis. An online store's marketing director was planning her budget. I analysed about 470,000 website visits across six tables in PostgreSQL. There was no channel column, so I built one from the tracking tags with a CASE statement. Comparing channels on conversion and revenue per visit — not just traffic — showed paid search drove most visits, but free, brand-driven traffic was growing fast and converting well. Mobile converted much worse than desktop. I mapped the page-by-page funnel to find the biggest drop-off, and calculated the most the company can pay per ad click for each device, so she had a real bidding number."

### Resume bullets

- "Marketing Channel & Funnel Analysis: analysed \~470k website sessions across 6 tables in PostgreSQL; built channel attribution from UTM data and compared conversion and revenue per session by channel and device."
- "Identified the largest funnel drop-off (\[X\]%) and set maximum profitable paid-search bids at $\[Y\] desktop / $\[Z\] mobile; delivered a 4-page Power BI dashboard."

### Questions interviewers will ask

- "How did you define channels?" — From utm\_source, utm\_campaign and referrer in a CASE statement.
- "Why revenue per session?" — It compares channels fairly regardless of size, and it sets the bid ceiling.
- "What would you need to calculate ROI?" — Ad spend per channel: ROI = (margin − spend) ÷ spend.


---

← [Back to all projects](../../README.md) · [Start here guide](../../START-HERE.md)
