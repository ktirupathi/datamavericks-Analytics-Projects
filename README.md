# Data Mavericks — Job-Ready Data Analytics Projects

**Five end-to-end analytics projects that feel like your first weeks at a real analyst job.** Real business questions, free public datasets, and only the tools analyst job descriptions ask for: **Excel, SQL and Power BI**.

Built for students, freshers and career switchers by **Venkata, Senior Data Scientist** · Follow [@datamavericks](https://www.instagram.com/datamavericks/) for practical Data & AI skills.

> 👉 **New to building projects? Read [START-HERE.md](START-HERE.md) first.** It walks you from a blank laptop to a published project in 10 steps — installing the tools, loading data, cleaning, analysis, Power BI, storytelling and GitHub.

---

## The 5 projects

| # | Project | The business question | Domain | Data | Tools | Level |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | [E-commerce Delivery Performance & Customer Retention Analysis](projects/01-ecommerce-delivery-retention-analysis/) | Do late deliveries hurt reviews and repeat orders — and where should we fix first? | E-commerce | ~100k orders, 9 tables | SQL + Power BI | Beginner–Intermediate |
| 2 | [Hotel Booking Cancellation & Revenue Risk Analysis](projects/02-hotel-cancellation-revenue-risk-analysis/) | How much revenue do cancellations put at risk, and which bookings should we watch? | Hotels / travel | ~119k bookings, 1 table | Excel Power Query + Power BI | Beginner |
| 3 | [B2B Sales Pipeline & Win-Rate Analysis](projects/03-b2b-sales-pipeline-win-rate-analysis/) | Which reps, products and accounts actually win deals — and what's in next quarter's pipeline? | B2B sales | ~8,800 deals, 4 tables | Excel + Power BI | Beginner |
| 4 | [Marketing Channel Attribution & Conversion Funnel Analysis](projects/04-marketing-channel-funnel-analysis/) | Which channels bring paying customers, and how much can we afford to spend per ad click? | Digital marketing | ~470k website sessions, 6 tables | SQL + Power BI | Intermediate |
| 5 | [Credit Card Customer Churn Analysis](projects/05-credit-card-churn-analysis/) | Which customers are about to leave, and how early can we tell? | Banking | ~10k customers, 1 table | SQL (or Excel) + Power BI | Beginner–Intermediate |

No Python required. Every guide is a 15-day plan at 1–2 hours a day.

## Why these projects

| Too routine (skip) | The sweet spot (these 5) | Too complex (later) |
| --- | --- | --- |
| Titanic, Iris, Superstore — everyone has them | A question anyone understands in one line | Tens of millions of rows, nested event data |
| One clean CSV, no joins | Related tables, or one rich table with real quirks | Pipelines, APIs, forecasting models |
| "Made a dashboard" with no decision | Ends with a recommendation and a number | So technical you can't explain it |
| Nothing to discover | A built-in finding to tell as a story | Insight buried under method |

## How every guide works

Each project is written as a **work simulation**, in the order a real task unfolds:

1. **The brief** — an email from your "manager" with the question.
2. **Know your data** — the tables, what one row means, and the messy bits to expect.
3. **The 5 questions** — what the manager actually needs answered.
4. **Build it, day by day** — exact clicks, every query and formula explained in plain words.
5. **You're on track if…** — checkpoints so you know you're not lost.
6. **Common mistakes** — what a reviewer would catch in your work.
7. **Tell the story** — the stakeholder readout, a 60-second interview explanation, resume bullets and the questions interviewers ask.

Each project folder also has the ready-made **SQL, DAX and Power Query** files used in the guide. All SQL has been tested on PostgreSQL 16.

## Which one should you pick?

- **Fresher:** start with Project 1 (SQL) or Project 2 (Excel). Then add one more from a different domain.
- **Career switcher:** pick the project closest to your past work — sales → 3, marketing → 4, banking/finance → 5, travel/hospitality → 2. Your domain knowledge is your edge in interviews.
- **Two projects are enough** for a resume. Done well beats many done shallow.

## A 3-week rhythm

| Week | Focus | Output by the end of the week |
| --- | --- | --- |
| 1 | Read the brief, load, explore and clean the data | A data notes file: tables, row counts, issues fixed |
| 2 | Answer the 5 questions; build the dashboard | Saved queries/pivots; a 2–4 page dashboard |
| 3 | Find the story, write recommendations, publish | One-page summary, GitHub README, LinkedIn post, a practised 60-second explanation |

## What "done" looks like

- **Your own GitHub repo** with a README (the brief, data, approach, 3 findings with numbers, recommendation), SQL files or Excel workbook, and dashboard screenshots.
- **A one-page summary** a manager could read in 2 minutes.
- **A 60-second explanation** you can say out loud without notes.

The guides use **[X] placeholders** for results on purpose. Your resume numbers must come from your own analysis.

## Repo structure

```
├── START-HERE.md                 ← setup + the 10-step method for any project
├── projects/
│   ├── 01-ecommerce-delivery-retention-analysis/
│   │   ├── README.md             ← the full day-by-day guide
│   │   ├── sql/                  ← load, explore, clean, analysis queries
│   │   └── powerbi/measures.dax
│   ├── 02-hotel-cancellation-revenue-risk-analysis/   (Power Query + DAX)
│   ├── 03-b2b-sales-pipeline-win-rate-analysis/       (Power Query + DAX)
│   ├── 04-marketing-channel-funnel-analysis/          (SQL + DAX)
│   └── 05-credit-card-churn-analysis/                 (SQL + DAX)
└── templates/                    ← README, data notes, insight log, summary, interview story, LinkedIn post
```

## How to use this repo

1. **⭐ Star it** so you can find it again.
2. **Pick one project** and read its guide from top to bottom before starting.
3. **Build in your own repo** — don't fork this one as your project. Copy the files from [templates/](templates/) into your new repo and fill them in as you go.
4. **Type the queries yourself.** Use the ready-made files only to check your work.

## Datasets

The datasets are free, but this repo doesn't include them. Download each one from its source, and check its terms of use there.

| Project | Dataset | Source |
| --- | --- | --- |
| 1 | Brazilian E-Commerce Public Dataset by Olist | [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| 2 | Hotel Booking Demand | [Kaggle](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand) |
| 3 | CRM Sales Opportunities | [Maven Analytics Data Playground](https://mavenanalytics.io/data-playground/crm-sales-opportunities) |
| 4 | Toy Store E-Commerce Database (Maven Fuzzy Factory) | [Maven Analytics Data Playground](https://mavenanalytics.io/data-playground/toy-store-e-commerce-database) |
| 5 | Credit Card Customers | [Kaggle](https://www.kaggle.com/datasets/sakshigoyal7/credit-card-customers) |

Projects 3 and 4 use realistic training datasets for fictitious companies. Say so honestly in your README and interviews.

## Built one? Share it

Open an issue using the **Project showcase** template with your repo link, or tag [@datamavericks](https://www.instagram.com/datamavericks/) on Instagram or LinkedIn. Good projects may be featured.

Found a mistake in a guide or query? Open an issue with the **Guide fix** template — see [CONTRIBUTING.md](CONTRIBUTING.md).

## License

Code (SQL, DAX, Power Query) is under the [MIT License](LICENSE). Guides and templates are under [CC BY 4.0](LICENSE-CONTENT.md) — share and adapt them with credit to Data Mavericks.
