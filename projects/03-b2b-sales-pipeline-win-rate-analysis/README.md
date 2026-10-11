# B2B Sales Pipeline & Win-Rate Analysis

You'll act as the new sales analyst at a company that sells computer hardware to businesses. In 15 working days you'll combine 4 CRM tables, define win rate correctly, compare reps fairly, and give the VP of Sales a clear picture of performance and next quarter's pipeline. Ideal if you're switching from sales, business development or operations. Setup: the [Start here guide](../../START-HERE.md) (Excel and Power BI only).

> 📂 **Ready-made files in this folder:** [`powerbi/measures.dax`](powerbi/measures.dax), [`power-query/custom-columns.txt`](power-query/custom-columns.txt). Use them to check your work — but type the queries yourself first; that's how you learn.

| Item | Detail |
| --- | --- |
| Project title | B2B Sales Pipeline & Win-Rate Analysis |
| One line for interviews | "I analysed a B2B sales pipeline to show which reps actually win deals — not just who sells the most — and what's coming next quarter." |
| Tools | Excel (Power Query merges, pivots, calculated fields) + Power BI |
| Data | Maven Analytics CRM Sales Opportunities — \~8,800 deals, 4 tables, Oct 2016 – Dec 2017 (fictitious company, realistic CRM structure) |
| Time | 15 days × 1–2 hours |
| Skills you'll be able to claim | Merging tables, KPI definitions, fair comparisons, date maths, DAX, pipeline forecasting |

## The brief

> **From:** Anil, VP Sales  
> **Subject:** Quarterly sales review — I need the real picture
>
> Hi — we moved to a new CRM but nobody can see the data outside it. For the quarterly review I need to know how each team and rep is really performing, which products win more, how long deals take, and what's in the pipeline for next quarter. I suspect some reps look good only because they sell expensive products. Can you check?

**Your 4 lines for the README:**

```
Stakeholder: Anil, VP Sales
Decision:    Who to coach, which products to re-price, which deals to push
Questions:   Quarterly results | rep & team performance | product win rates & discounts | sales cycle | pipeline
Success:     A fair rep ranking, 2–3 product/process fixes, and an expected-pipeline number
```

## Your 15-day plan

| Day | Task | Output |
| --- | --- | --- |
| 1 | Brief, folders, download | Folder ready |
| 2 | Look at the 4 tables + data dictionary | data\_notes.md |
| 3 | Power Query: load and fix the product name | Clean tables |
| 4 | Power Query: merge into one deals table | Merged table, row count checked |
| 5 | Power Query: add calculated columns, load | Final table + cleaning log |
| 6 | Win rate — the right definition | Overall KPIs |
| 7 | Q1 — results by quarter | Insight 1 |
| 8 | Q2 — teams and reps | Insights 2–3 |
| 9 | Q2 — the fairness check | Insight 4 |
| 10 | Q3, Q4, Q5 — products, cycle, pipeline | Insights 5–7 |
| 11 | Power BI: load and measures | Model ready |
| 12 | Power BI: 4 pages | Dashboard |
| 13 | Story + one-page summary | Summary |
| 14 | README + GitHub | Published repo |
| 15 | LinkedIn + practise | Done |

## Week 1 — Get the data ready

### Day 1 — Brief and setup

1. Create the folder `sales-pipeline-analysis`.
2. Go to [CRM Sales Opportunities (Maven Analytics Data Playground)](https://mavenanalytics.io/data-playground/crm-sales-opportunities) → download (free) → unzip into `data/raw/`.
3. Paste the 4 README lines.

### Day 2 — Meet the data

Open each CSV and the data dictionary file in the download.

| Table | One row is… | Key | Columns |
| --- | --- | --- | --- |
| sales\_pipeline | One deal (opportunity) | opportunity\_id | sales\_agent, product, account, deal\_stage, engage\_date, close\_date, close\_value |
| sales\_teams | One sales agent | sales\_agent | manager, regional\_office |
| products | One product | product | series, sales\_price (list price) |
| accounts | One customer company | account | sector, year\_established, revenue, employees, office\_location, subsidiary\_of |

**deal\_stage** has 4 values: Prospecting (early), Engaging (in talks), Won, Lost. The first two are **open** deals.

Things to note: Prospecting deals have no account and no dates yet; Lost deals have close\_value 0; open deals have no close\_date. Now compare the product names in `sales_pipeline` with those in `products` — one product is spelled slightly differently in the two tables. Find it and write it down; it will matter on Day 3.

### Day 3 — Load and fix in Power Query

Open a new Excel workbook. For **each** of the 4 CSVs: Data → Get Data → From Text/CSV → **Transform Data** → in Power Query, Home → **Close & Load To…** → **Only Create Connection**. (This keeps them as queries without filling 4 sheets.)

Then open the Power Query editor (Data → Get Data → Launch Power Query Editor) → select `sales_pipeline` → select the product column → Home → **Replace Values** → replace the mismatched spelling with the one used in `products`.

Check types: engage\_date and close\_date = Date; close\_value and sales\_price = Decimal.

### Day 4 — Merge into one deals table

With `sales_pipeline` selected in Power Query:

1. Home → **Merge Queries** → second table `sales_teams` → click `sales_agent` in both → Join kind **Left Outer** → OK. A new column appears; click its expand icon (two arrows) → tick manager and regional\_office → untick "Use original column name as prefix" → OK.
2. Merge again with `products` on product → expand series and sales\_price.
3. Merge again with `accounts` on account → expand sector, revenue, employees, office\_location.

**Why Left Outer:** it keeps every deal, even if it has no matching account (Prospecting deals). An Inner join would silently delete them.

**Check:** Home → Close & Load to a sheet → the row count must equal the original sales\_pipeline count. If it's higher, a lookup table has duplicates; if lower, you used an Inner join.

### Day 5 — Add calculated columns

Back in Power Query on the merged table, Add Column → **Custom Column** for each:

```
Is Closed         = if [deal_stage] = "Won" or [deal_stage] = "Lost" then 1 else 0
Is Won            = if [deal_stage] = "Won" then 1 else 0
Is Open           = if [deal_stage] = "Prospecting" or [deal_stage] = "Engaging" then 1 else 0
Cycle Days        = if [Is Closed] = 1 then Duration.Days([close_date] - [engage_date]) else null
Price Realisation = if [deal_stage] = "Won" then [close_value] / [sales_price] else null
Close Quarter     = if [close_date] = null then null
                    else Text.From(Date.Year([close_date])) & "-Q" & Text.From(Date.QuarterOfYear([close_date]))
```

Set types: the flags to Whole Number, Cycle Days to Whole Number, Price Realisation to Decimal (format later as %). Close & Load. Name the table `Deals`.

**Price Realisation** = how much of the list price we actually got. 0.95 means a 5% discount.

## Week 2 — Answer the questions

### Day 6 — Win rate: get the definition right

**Win rate = Won ÷ (Won + Lost).** Open deals are not losses yet, so they don't belong in the bottom of the fraction. Getting this right is the single most important thing in this project — interviewers often test it.

In a pivot from `Deals`: add **Sum of Is Won** and **Sum of Is Closed** to Values. Then PivotTable Analyze → Fields, Items & Sets → **Calculated Field** → Name: `Win Rate`, Formula: `='Is Won' / 'Is Closed'` → OK → format as %.

Also add: Sum of close\_value (revenue), Count of opportunity\_id (deals). Write the overall numbers in your insight log.

### Day 7 — Q1: Results by quarter

Pivot: Rows = Close Quarter (filter out blank); Values = Is Won (sum), close\_value (sum), Win Rate. Add a PivotChart (Line) for revenue.

Insight: "We closed $\[X\] in \[period\]; win rate ranged from \[A\]% to \[B\]% by quarter; \[quarter\] was strongest."

### Day 8 — Q2: Teams and reps

Pivot: Rows = regional\_office → manager → sales\_agent (drag all three, in that order); Values = revenue, deals won, Win Rate, and **Average of close\_value** for won deals (filter deal\_stage = Won in a separate pivot for deal size).

Sort reps by revenue, then by Win Rate. Highlight the reps whose position changes most between the two lists — that's the start of Anil's answer.

Insights: "\[Office\] leads on revenue; \[manager\]'s team has the best win rate. \[N\] reps are below \[X\]% win rate."

### Day 9 — Q2: The fairness check

Anil suspects some reps look good because they sell expensive products. Test it:

1. Pivot: Rows = sales\_agent, Columns = series, Values = Win Rate and Sum of close\_value.
2. Look at each top-revenue rep: is their revenue mostly from the most expensive series? Is their win rate within that series better or worse than colleagues selling the same series?
3. Make a simple scatter in Excel (Insert → Scatter) from a small table: X = win rate, Y = revenue, one point per rep. Reps in the bottom-right (high win rate, low revenue) might deserve bigger accounts; top-left (high revenue, low win rate) might need coaching.

Insight: "Ranking by revenue vs by win rate changes \[N\] of the top 10; \[Rep\] earns most but wins only \[X\]% — mainly on \[series\]."

### Day 10 — Q3, Q4, Q5: Products, cycle, pipeline

1. **Products (Q3):** Rows = product; Values = Win Rate, Average of Price Realisation (format %), revenue. Which product rarely wins? Which is sold at the deepest discount?
2. **Sales cycle (Q4):** Rows = deal\_stage (filter to Won and Lost); Values = Average of Cycle Days. Do lost deals drag on longer? Then Rows = product, same value.
3. **Pipeline (Q5):** filter Is Open = 1; Rows = deal\_stage, sales\_agent; Values = Count of deals, Sum of sales\_price (open deals have no close value, so list price shows potential).
4. **Deal age:** add a column in the sheet: `=IF([@[Is Open]]=1, MAX(Deals[close_date]) - [@[engage_date]], "")` — days since engagement up to the last date in the data. Deals much older than the average won-deal cycle are "stuck".
5. **Expected pipeline:** Engaging deals' list value × overall win rate × average price realisation. Write it as an estimate.

### Day 11 — Power BI: load and measures

Get data → Excel workbook → tick `Deals` → Load. New measures:

```
Deals Count = COUNTROWS ( Deals )
Won = CALCULATE ( [Deals Count], Deals[deal_stage] = "Won" )
Closed = CALCULATE ( [Deals Count], Deals[deal_stage] IN { "Won", "Lost" } )
Win Rate = DIVIDE ( [Won], [Closed] )
Revenue = SUM ( Deals[close_value] )
Avg Deal Size = DIVIDE ( [Revenue], [Won] )
Avg Cycle Days = CALCULATE ( AVERAGE ( Deals[Cycle Days] ), Deals[Is Closed] = 1 )
Avg Price Realisation = AVERAGE ( Deals[Price Realisation] )
Open Pipeline Value = CALCULATE ( SUM ( Deals[sales_price] ), Deals[deal_stage] = "Engaging" )
Expected Pipeline = [Open Pipeline Value] * CALCULATE ( [Win Rate], ALL ( Deals ) ) * CALCULATE ( [Avg Price Realisation], ALL ( Deals ) )
```

`ALL ( Deals )` uses the company-wide win rate and discount, so the estimate doesn't change oddly when you filter by rep.

### Day 12 — Power BI: build the 4 pages

**Page 1 — "$\[X\] closed at a \[Y\]% win rate"**: 4 Cards (Revenue, Won, Win Rate, Avg Deal Size); Line chart of Revenue by Close Quarter; slicers for regional\_office and manager.

**Page 2 — "Revenue vs win rate by rep" (hero page)**: **Scatter chart** — Values = sales\_agent, X = Win Rate, Y = Revenue, Size = Won. Add average lines (Analytics pane → Average line for X and Y) to split it into 4 quadrants. Next to it, a Table of reps with Revenue, Win Rate, Won, Avg Deal Size, with conditional formatting on Win Rate.

**Page 3 — "Products and speed"**: Bar chart Win Rate by product; Bar chart Avg Price Realisation by product; Clustered column of Avg Cycle Days for Won vs Lost.

**Page 4 — "Next quarter's pipeline"**: Cards for Open Pipeline Value and Expected Pipeline; Stacked bar of open deals by sales\_agent and deal\_stage; a Table of the oldest open deals.

Save as `dashboard/sales_pipeline.pbix` and screenshot each page.

## Week 3 — Tell the story and publish

### Day 13 — The one-page summary

```
B2B Sales Pipeline & Win-Rate Analysis

The question: How are reps, teams and products really performing, and what's coming next quarter?

What I found:
  1. $[X] closed at a [Y]% win rate; [quarter] was strongest.
  2. Revenue and win-rate rankings disagree for [N] reps — [Rep A] tops revenue on expensive [series] but wins only [Z]%.
  3. [Product] wins only [W]% of the time and sells at [V]% of list price.
  4. Lost deals take [A] days on average vs [B] for won ones — deals stuck beyond [C] days rarely close.

What I recommend:
  1. Coach the [N] reps below [X]% win rate, paired with top closers.
  2. Review [product]'s pricing and positioning.
  3. Flag Engaging deals older than [C] days for weekly manager review.
  Expected pipeline next quarter: about $[E] (estimate).

Limits: fictitious company; win rate ignores deal difficulty; forecast uses averages.
```

### Day 14 — README and GitHub

Repo name: `sales-pipeline-analysis`. Upload the workbook (queries + pivots), .pbix, images, notes and summary. Put the rep scatter chart at the top of the README.

### Day 15 — LinkedIn and practice

Post with the scatter chart: "Your top seller might not be your best closer." Practise the 60-second story.

## You're on track if…

- The merged table has exactly as many rows as sales\_pipeline.
- No product shows 0 deals after the merge (if one does, the name fix didn't work).
- Your win rate on closed deals is clearly higher than "won ÷ all deals".

## Common mistakes I'd catch in a review

- Dividing wins by all deals, including open ones.
- Using Inner joins and losing Prospecting deals.
- Ranking reps on revenue only.
- Presenting the pipeline forecast as a certain number.

## Tell the story

### Your 60-second interview explanation

> "My project is a B2B sales pipeline and win-rate analysis. A VP of Sales wanted the real picture of his team's performance from their CRM. I merged four tables — deals, reps, products and accounts — in Power Query, and found a product-name mismatch that was silently dropping deals. I defined win rate properly, as wins over closed deals only. When I compared reps on both revenue and win rate, the rankings changed — some top earners were just selling the most expensive products. I also found deals that stay in talks too long rarely close, so I recommended a review rule and estimated next quarter's pipeline in Power BI."

### Resume bullets

- "B2B Sales Pipeline & Win-Rate Analysis: merged 4 CRM tables (\~8,800 deals) in Power Query and built a Power BI sales dashboard tracking revenue, win rate, deal size and sales cycle by rep, team and product."
- "Showed revenue and win-rate rankings diverge for \[N\] reps, flagged a low-win, discounted product, and estimated next-quarter expected pipeline at $\[X\]."

### Questions interviewers will ask

- "How do you define win rate?" — Won ÷ (Won + Lost); open deals excluded.
- "How did you make rep comparisons fair?" — Compared within the same product series and showed deal counts.
- "How reliable is the forecast?" — Rough; I'd improve it with stage-specific win rates and deal age.


---

← [Back to all projects](../../README.md) · [Start here guide](../../START-HERE.md)
