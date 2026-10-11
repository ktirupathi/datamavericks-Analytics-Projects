# Start Here — Build Any Analytics Project From Scratch

Every analytics project, at any company, follows the same 10 steps. Learn them once here, then follow the project guide of your choice — each one assumes you've done the setup on this page.

> 🧰 Fill-in templates for every file mentioned below (README, data notes, insight log, summary, interview story, LinkedIn post) are in [templates/](templates/).

**The 10 steps:** 1. Set up → 2. Understand the brief → 3. Get the data → 4. Load it → 5. Explore it → 6. Clean it → 7. Analyse it → 8. Build the dashboard → 9. Tell the story → 10. Publish and practise.

## Step 1 — Set up your laptop (one time, \~1 hour)

| Tool | What it's for | Where to get it | Notes |
| --- | --- | --- | --- |
| Microsoft Excel | Quick looks at data, Power Query cleaning, pivots | Office 365 (or free Excel on the web for basics) | Power Query is under Data → Get Data |
| PostgreSQL + pgAdmin | Your SQL database | [postgresql.org/download](https://www.postgresql.org/download/) — the installer includes pgAdmin | Write down the password you set during install |
| Power BI Desktop | Dashboards | [Power BI Desktop download](https://powerbi.microsoft.com/desktop/) or the Microsoft Store | Windows only. Mac users: use Tableau Public instead — the steps map closely |
| GitHub account | Your portfolio | [github.com](https://github.com) | No need to learn Git commands — you can upload files in the browser |
| A notes file | Your thinking | Notepad, Google Docs, or Notion | You'll keep a "data notes" and an "insight log" |

**Test your setup:** open pgAdmin → expand Servers → PostgreSQL → enter your password. Right-click **Databases** → Create → Database → name it `practice`. If it appears in the list, you're ready.

## Step 2 — Create your project folder

Make one folder per project, the same way every time. Interviewers notice tidy repos.

```
ecommerce-delivery-analysis/
├── data/
│   ├── raw/          ← downloaded files, never edited
│   └── clean/        ← exports you create
├── sql/              ← 01_load.sql, 02_explore.sql, 03_clean.sql, 04_analysis.sql
├── dashboard/        ← the .pbix file
├── images/           ← dashboard screenshots
├── data_notes.md     ← what the data is and what you fixed
├── insight_log.md    ← every finding with its number
└── README.md         ← the front page of your project
```

**Golden rule:** never change files in `data/raw`. If you make a mistake later, you can always start again from the original.

## Step 3 — Understand the brief before touching data (30 minutes)

Read your project's brief and write these 4 lines at the top of `README.md`:

```
Stakeholder: Who asked? (e.g. Head of Customer Experience)
Decision:    What will they decide with my answer? (e.g. where to fix delivery first)
Questions:   The 5 questions I must answer
Success:     What a useful answer looks like (e.g. top 3 states to fix, with numbers)
```

Why: analysts who start with the decision finish faster and present better. If a chart doesn't help the decision, it doesn't go in.

## Step 4 — Get the data and look at it in Excel first (30 minutes)

1. Download from the link in your project guide into `data/raw/`. Unzip if needed.
2. Open each CSV in Excel (just to look — don't save changes).
3. For each file, fill this in `data_notes.md`:

```
Table: orders
One row is: one order
Rows: 99,441
Key column (unique per row): order_id
Links to: customers via customer_id
Columns I'll use: ...
Things that look odd: blank delivery dates on some rows; dates stored as text
```

"One row is…" (the **grain**) is the single most important thing to know about any table. Most beginner mistakes come from not knowing it.

## Step 5 — Load the data into PostgreSQL

**5a. Create a database** for the project: pgAdmin → right-click Databases → Create → Database → e.g. `ecommerce_delivery`.

**5b. Create a table for each CSV.** The beginner-safe method: create every column as `TEXT` first, load, then convert types in SQL. This avoids most import errors.

```sql
-- Example: copy column names from the CSV header row
CREATE TABLE raw_orders (
  order_id TEXT,
  customer_id TEXT,
  order_status TEXT,
  order_purchase_timestamp TEXT,
  order_delivered_customer_date TEXT,
  order_estimated_delivery_date TEXT
  -- ...one line per column, in the same order as the CSV
);
```

Open the Query Tool (Tools → Query Tool), paste, and press F5. Save every script in your `sql/` folder.

**5c. Import the CSV:** in the left panel, expand your database → Schemas → public → Tables → right-click the table → **Import/Export Data** → toggle **Import** → choose the file → Options tab: **Header = on**, Delimiter = `,` → OK.

**5d. Check it worked:**

```sql
SELECT COUNT(*) FROM raw_orders;   -- should match the row count in your data notes
SELECT * FROM raw_orders LIMIT 10; -- eyeball the first rows
```

**Common import errors and fixes:**

| Error message mentions… | Cause | Fix |
| --- | --- | --- |
| "extra data after last expected column" | Your table has fewer columns than the CSV | Count the CSV columns again; add the missing ones |
| "invalid input syntax for type…" | A column isn't TEXT and has a bad value | Use TEXT for every column at load time |
| "permission denied" | pgAdmin can't read the folder | Move the CSV to a simple path like `C:\data\` |
| Strange characters (Ã©) | Encoding | In Options, set Encoding to UTF8 |

## Step 6 — Explore: the 6 checks for every table (1–2 hours)

Run these on every table and record the results in `data_notes.md`.

```sql
-- 1. How many rows?
SELECT COUNT(*) FROM raw_orders;

-- 2. Is the key really unique?
SELECT COUNT(*) AS rows, COUNT(DISTINCT order_id) AS unique_ids FROM raw_orders;

-- 3. How many blanks in important columns?
SELECT
  SUM(CASE WHEN order_delivered_customer_date IS NULL OR order_delivered_customer_date = '' THEN 1 ELSE 0 END) AS missing_delivery
FROM raw_orders;

-- 4. What values does a category column have?
SELECT order_status, COUNT(*) FROM raw_orders GROUP BY 1 ORDER BY 2 DESC;

-- 5. What date range does the data cover?
SELECT MIN(order_purchase_timestamp), MAX(order_purchase_timestamp) FROM raw_orders;

-- 6. Do the tables join properly? (rows that find no match)
SELECT COUNT(*) FROM raw_orders o
LEFT JOIN raw_customers c ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;
```

If check 2 shows `rows` > `unique_ids`, the table has duplicates — write that down; you'll handle it in cleaning.

## Step 7 — Clean: create a clean version, never edit raw (2–4 hours)

Create a **view** or table that converts types and applies your rules. Every rule goes into `data_notes.md` with how many rows it affected.

```sql
CREATE TABLE orders AS
SELECT
  order_id,
  customer_id,
  order_status,
  NULLIF(order_purchase_timestamp, '')::timestamp      AS purchase_ts,
  NULLIF(order_delivered_customer_date, '')::timestamp AS delivered_ts,
  NULLIF(order_estimated_delivery_date, '')::timestamp AS estimated_ts
FROM raw_orders;
```

`NULLIF(x, '')` turns empty text into a real blank (NULL) so the type conversion doesn't fail. `::timestamp` converts text to a date-time.

**The cleaning checklist:** convert types → turn empty strings into NULL → remove or flag impossible values (negative prices, dates in the future) → de-duplicate → standardise text (spelling, case, trimming spaces) → decide what to do with blanks (exclude, fill, or keep as "Unknown") — and write down every decision.

## Step 8 — Analyse: one question, one query, one sentence (4–8 hours)

For each of the 5 questions in your project:

1. Write the query (your project guide gives you a starting version).
2. Run it and look at the result — does it make sense? Does the total match what you expect?
3. Write **one sentence** in `insight_log.md` with the number:

```
Q2 | Late orders average [X] stars vs [Y] for on-time orders (n = [N] orders) | sql/04_analysis.sql line 20
```

4. Ask "so what?" — what should the stakeholder do because of this? Write that too.

By the end you'll have 8–12 insights. You'll use the best 3 in your story.

## Step 9 — Build the dashboard in Power BI (4–6 hours)

**9a. Get the data in.** Two options:

- **Connect to PostgreSQL:** Home → Get data → More → PostgreSQL database → Server: `localhost`, Database: your database name → choose your clean tables. (If Power BI asks for a driver, use option b.)
- **Export CSVs:** in pgAdmin, right-click a table → Import/Export Data → **Export** to `data/clean/` → in Power BI, Get data → Text/CSV.

**9b. Model view** (left sidebar, third icon): drag the key column from one table onto the matching column in the other to create relationships. Check the arrows go from the lookup table (one) to the detail table (many).

**9c. Measures, not dragged columns.** Right-click your main table → New measure. Your project guide lists the exact measures (and its powerbi/measures.dax file has them ready to copy). Measures make your numbers consistent across every visual.

**9d. Lay out each page the same way:**

```
┌──────────────────────────────────────────────┐
│ Title = the finding (not "Sales Dashboard")   │
├──────────┬──────────┬──────────┬─────────────┤
│ KPI card │ KPI card │ KPI card │ Slicer(s)   │
├──────────┴──────────┴──────────┴─────────────┤
│ Main chart (the one that proves the finding) │
├───────────────────────┬──────────────────────┤
│ Supporting chart      │ Supporting table      │
└───────────────────────┴──────────────────────┘
```

**Design rules:** maximum 4–5 visuals per page; one highlight colour for the thing that matters, grey for the rest; every chart title says what it shows ("Late orders get 1.7 fewer stars"), not just the field names; add data labels instead of gridlines.

**9e. Save** the .pbix in `dashboard/`, then take a screenshot of each page (Windows: Win + Shift + S) into `images/`.

**Sharing:** "Publish to web" needs a work or school account. Freshers can instead upload the .pbix to GitHub and screenshots to the README, or use a free portfolio site like [NovyPro](https://www.novypro.com).

## Step 10 — Tell the story, publish, and practise

### 10a. The one-page summary (what a manager reads)

```
Title: E-commerce Delivery Performance & Customer Retention Analysis

The question: [one line from the brief]
What I found:
  1. [finding + number]
  2. [finding + number]
  3. [finding + number]
What I recommend:
  1. [action] — expected impact: [number]
  2. [action]
Assumptions and limits: [2–3 honest lines]
Next steps with more data: [1–2 lines]
```

### 10b. The README (the front page of your GitHub repo)

```
# E-commerce Delivery Performance & Customer Retention Analysis
![Dashboard](images/page1.png)

## Business problem
## Data (source link, tables, rows, period)
## Approach (load → clean → analyse → dashboard, with tools)
## Key findings (3 bullets with numbers)
## Recommendations
## Files in this repo
## What I'd do next
```

**Upload to GitHub without Git:** github.com → New repository → name it `ecommerce-delivery-analysis` → Public → Create → "uploading an existing file" → drag your folder contents in (skip large raw data files; link to the source instead) → Commit.

### 10c. The LinkedIn post

Hook question → 3 findings with numbers → one dashboard image → link to GitHub. Post it, and pin it to your Featured section.

### 10d. The interview story (practise out loud 5 times)

Use this 4-part structure for any project — it takes about 60 seconds:

1. **Problem:** "The \[stakeholder\] wanted to know \[question\]."
2. **Data:** "I used \[data\] — \[size, tables\]."
3. **What I did:** "I \[cleaned X\], \[built Y\], and found \[the main finding with a number\]."
4. **Result:** "I recommended \[action\], which could \[impact\]."

Then be ready for the 5 questions every interviewer asks about projects:

- What was the hardest part of the data, and how did you handle it?
- Why did you choose that metric/definition?
- How do you know your numbers are right? (Mention your checks: row counts, unique keys, totals.)
- What would you do differently or next?
- If the stakeholder disagreed with your finding, what would you do?


---

← [Back to all projects](README.md)
