# Hotel Booking Cancellation & Revenue Risk Analysis

You'll act as the analyst for two hotels. In 15 working days you'll clean a real booking file in Excel, put a money value on cancellations, find which bookings are risky, and recommend a deposit and overbooking policy. No SQL needed — perfect as a first project. Do the setup in the [Start here guide](../../START-HERE.md) first (you only need Excel and Power BI for this one).

> 📂 **Ready-made files in this folder:** [`powerbi/measures.dax`](powerbi/measures.dax), [`power-query/custom-columns.txt`](power-query/custom-columns.txt). Use them to check your work — but type the queries yourself first; that's how you learn.

| Item | Detail |
| --- | --- |
| Project title | Hotel Booking Cancellation & Revenue Risk Analysis |
| One line for interviews | "I measured how much revenue two hotels lose to cancellations and which bookings are most likely to cancel." |
| Tools | Excel (Power Query, pivot tables) + Power BI |
| Data | \~119,000 real bookings from a City Hotel and a Resort Hotel in Portugal, July 2015 – August 2017 (prices in euros) |
| Time | 15 days × 1–2 hours |
| Skills you'll be able to claim | Power Query cleaning, calculated columns, pivot tables, rate analysis, revenue calculations, Power BI DAX and design |

## The brief

> **From:** Rahul, Revenue Manager  
> **Subject:** Cancellations are killing our occupancy
>
> Hi — over a third of our bookings seem to cancel and rooms end up empty. Before we change our deposit or overbooking policy, I need facts: how big is the problem in money, which kinds of bookings cancel most, and what should we change? Please keep it simple — I'll present it to the GM.

**Your 4 lines for the README:**

```
Stakeholder: Rahul, Revenue Manager (presenting to the General Manager)
Decision:    Change deposit rules and/or overbook, and for which bookings
Questions:   Cancel rate | revenue at risk | which bookings cancel | commitment signals | policy
Success:     A euro figure for the problem and 2–3 targeted policy changes
```

## Your 15-day plan

| Day | Task | Output |
| --- | --- | --- |
| 1 | Brief, folders, download | Folder ready |
| 2 | Explore the file in Excel | data\_notes.md |
| 3 | Power Query: types and blanks | Clean types |
| 4 | Power Query: new columns | Arrival date, nights, revenue, bands |
| 5 | Power Query: remove bad rows, load | Clean table + cleaning log |
| 6 | Q1 — cancel rate | Insight 1 |
| 7 | Q2 — revenue at risk | Insight 2 |
| 8 | Q3 — who cancels (lead time, deposit) | Insights 3–4 |
| 9 | Q3 — who cancels (segment, customer type, history) | Insights 5–6 |
| 10 | Q4 & Q5 — commitment signals and the watch list | Insights 7–8 |
| 11 | Power BI: load, measures | Model ready |
| 12 | Power BI: 3 pages | Dashboard |
| 13 | Story + one-page summary | Summary |
| 14 | README + GitHub | Published repo |
| 15 | LinkedIn + practise | Done |

## Week 1 — Get the data ready

### Day 1 — Brief and setup

1. Create the folder `hotel-cancellation-analysis` with the structure from the [Start here guide](../../START-HERE.md) (you won't need the `sql/` folder).
2. Download [Hotel Booking Demand (Kaggle)](https://www.kaggle.com/datasets/jessemostipak/hotel-booking-demand) → unzip `hotel_bookings.csv` into `data/raw/`.
3. Paste the 4 README lines.

### Day 2 — Meet the data

Open the CSV in Excel. One row is **one booking**. Press Ctrl + Down to see the row count (\~119,390 including the header). Group the 32 columns in your notes:

| Group | Columns | What they mean |
| --- | --- | --- |
| Outcome | is\_canceled, reservation\_status, reservation\_status\_date | 1 = cancelled; status is Check-Out, Canceled or No-Show |
| Hotel | hotel | City Hotel or Resort Hotel |
| Timing | lead\_time, arrival\_date\_year, arrival\_date\_month, arrival\_date\_week\_number, arrival\_date\_day\_of\_month | lead\_time = days between booking and arrival |
| Stay | stays\_in\_weekend\_nights, stays\_in\_week\_nights | Nights booked |
| Guests | adults, children, babies, country, is\_repeated\_guest, previous\_cancellations, previous\_bookings\_not\_canceled, customer\_type | customer\_type: Transient, Contract, Group, Transient-Party |
| Channel | market\_segment, distribution\_channel, agent, company | Online TA = online travel agents |
| Deposit | deposit\_type | No Deposit, Non Refund, Refundable |
| Room | reserved\_room\_type, assigned\_room\_type, booking\_changes | — |
| Price | adr | Average daily rate in euros |
| Extras | meal, required\_car\_parking\_spaces, total\_of\_special\_requests, days\_in\_waiting\_list | — |

Now scan for oddities and write them down. You should find: "NA" text in children; "NULL" text in agent and company; month as a word ("July"); some bookings with 0 adults, 0 children and 0 babies; some with 0 nights; adr values that are 0, negative, or very large.

### Day 3 — Power Query: types and blanks

Open a new Excel workbook → Data → Get Data → From File → From Text/CSV → select the file → **Transform Data**. The Power Query editor opens. Every step you do is recorded on the right under "Applied Steps" — you can click any step to undo it.

1. **children:** select the column → Home → Replace Values → Value to find `NA`, Replace with `0` → OK. Then click the type icon on the column header → Whole Number.
2. **agent** and **company:** select both (Ctrl+click) → Replace Values → `NULL` → leave "Replace with" empty → OK. (They become blank.)
3. Check types: adr = Decimal Number; lead\_time, adults, babies, the stay columns = Whole Number; is\_canceled = Whole Number.

### Day 4 — Power Query: new columns

Add Column → **Custom Column** for each (name on the left, formula on the right):

```
month_num      = Date.Month(Date.FromText("1 " & [arrival_date_month] & " 2000"))
arrival_date   = #date([arrival_date_year], [month_num], [arrival_date_day_of_month])
total_nights   = [stays_in_weekend_nights] + [stays_in_week_nights]
total_guests   = [adults] + [children] + [babies]
booking_value  = [adr] * [total_nights]
```

Set arrival\_date to type Date, the counts to Whole Number, booking\_value to Decimal.

**How month\_num works:** Power Query can't turn "July" into 7 directly, so we build the text "1 July 2000", convert it to a date, and take its month. A neat trick worth mentioning in interviews.

Then Add Column → **Conditional Column** named `lead_band`:

| If lead\_time is less than or equal to | Output |
| --- | --- |
| 7 | 0–7 days |
| 30 | 8–30 days |
| 90 | 31–90 days |
| 180 | 91–180 days |
| 365 | 181–365 days |
| Else | 365+ days |

And one for special requests: `requests_band` = "0", "1", "2+" from total\_of\_special\_requests.

### Day 5 — Remove bad rows and load

1. Filter **total\_guests**: click the dropdown → Number Filters → Greater Than → 0.
2. Filter **total\_nights**: Greater Than → 0.
3. Filter **adr**: Between 0 and 1000 (Number Filters → Between: greater than or equal to 0, less than or equal to 1000).
4. Home → **Close & Load** → it loads into a new sheet as a Table.

Row count now vs. before: write the difference in your cleaning log, e.g. "Removed \[N\] bookings (0 guests, 0 nights or impossible prices) — \[X\]% of data." Rename the table `Bookings` (Table Design → Table Name).

## Week 2 — Answer the questions

**The pivot-table trick you'll use all week:** is\_canceled is 1 or 0, so its **Average** is the cancellation rate. Insert → PivotTable → from `Bookings` → drag a field to Rows, `hotel` to Columns, `is_canceled` to Values → click it → Value Field Settings → **Average** → Number Format → Percentage. Add `is_canceled` again as **Count** so you always see how many bookings each rate is based on.

### Day 6 — Q1: How often do bookings cancel?

1. Pivot: Columns = hotel, Values = Average of is\_canceled, Count of is\_canceled. → overall rate per hotel.
2. Pivot: Rows = arrival\_date\_year and month\_num → seasonal pattern. Insert → PivotChart → Line.

Insight: "\[X\]% of bookings cancel — \[Y\]% at the City Hotel vs \[Z\]% at the Resort Hotel; peaks in \[months\]."

### Day 7 — Q2: How much revenue is at risk?

Pivot: Rows = hotel, Columns = is\_canceled, Values = **Sum** of booking\_value.

Add a cell beside it: `= cancelled value / (cancelled + not cancelled)` → share of booked revenue that cancelled.

**Be careful with the wording:** some cancelled rooms are resold to other guests, so this isn't all "lost". Call it **revenue at risk**. Insight: "Cancelled bookings were worth €\[X\] — \[Y\]% of all booked revenue."

### Day 8 — Q3a: Lead time and deposit type

1. Rows = lead\_band (sort it in order: right-click → Sort → or drag items). You'll likely see the rate climb as lead time grows.
2. Rows = deposit\_type.

**The "aha" to investigate:** if "Non Refund" bookings show a very high cancellation rate, that looks backwards — why would people who can't get money back cancel more? Don't stop at the number. Filter the pivot to deposit\_type = Non Refund and put market\_segment, then country, then customer\_type in Rows. See where these bookings come from. Write what you find, and say it needs confirming with the sales team. Explaining a strange number is what managers value most.

### Day 9 — Q3b: Channel, customer type and history

Three more pivots (same Values each time):

1. Rows = market\_segment (and distribution\_channel).
2. Rows = customer\_type, then is\_repeated\_guest.
3. Rows = previous\_cancellations — group it: right-click a value → Group isn't available for small integers, so add a quick column in the table: `=IF([@previous_cancellations]=0,"0",IF([@previous_cancellations]=1,"1","2+"))` and refresh the pivot.

Insights: "\[Segment\] cancels most at \[X\]%"; "Repeat guests cancel at \[X\]% vs \[Y\]% for first-timers"; "Guests with a past cancellation cancel at \[X\]%."

### Day 10 — Q4 & Q5: Commitment signals and the watch list

1. Rows = requests\_band; then Rows = required\_car\_parking\_spaces. Guests who ask for things are usually committed — check if the rate drops.
2. **Watch list:** Rows = market\_segment, Columns = lead\_band, Values = Average of is\_canceled. Home → Conditional Formatting → Color Scales on the values. The darkest cells with enough bookings (check the counts) are the bookings Rahul's team should watch.
3. Rough policy maths: pick the riskiest cell (e.g. one segment booked 90+ days ahead). Count its bookings and cancellations. If a deposit cut cancellations there by a quarter, how much booking value would be saved? Write it as an estimate with the assumption stated.

### Day 11 — Power BI: load and measures

Power BI → Get data → Excel workbook → select your file → tick the `Bookings` table → Load. Then New measure for each:

```
Bookings Count = COUNTROWS ( Bookings )
Cancel Rate = AVERAGE ( Bookings[is_canceled] )
Booked Value = SUM ( Bookings[booking_value] )
Value at Risk = CALCULATE ( [Booked Value], Bookings[is_canceled] = 1 )
Realised Value = CALCULATE ( [Booked Value], Bookings[is_canceled] = 0 )
Risk Share = DIVIDE ( [Value at Risk], [Booked Value] )
Avg ADR = AVERAGE ( Bookings[adr] )
```

Format Cancel Rate and Risk Share as Percentage; Value measures as Currency (€).

**Sort lead\_band properly:** in Table view, add a column `lead_order = SWITCH(Bookings[lead_band], "0–7 days",1, "8–30 days",2, "31–90 days",3, "91–180 days",4, "181–365 days",5, 6)`, then select lead\_band → Column tools → **Sort by column** → lead\_order.

### Day 12 — Power BI: build the 3 pages

**Page 1 — "€\[X\] of bookings cancel every year"**

1. 4 **Cards**: Bookings Count, Cancel Rate, Value at Risk, Risk Share.
2. **Line chart**: X = arrival\_date (Month hierarchy level), Y = Cancel Rate, Legend = hotel.
3. **Slicer**: hotel (buttons style: Format → Slicer settings → Style → Tile).

**Page 2 — "Who cancels"**

1. **Column chart**: X = lead\_band, Y = Cancel Rate (data labels on).
2. **Bar chart**: market\_segment by Cancel Rate, sorted descending.
3. **Bar chart**: deposit\_type by Cancel Rate, with a text box explaining the Non Refund finding.
4. **Column chart**: requests\_band by Cancel Rate — the "committed guests" signal.

**Page 3 — "The watch list"**

1. **Matrix**: Rows = market\_segment, Columns = lead\_band, Values = Cancel Rate → Format → Cell elements → Background colour on. Add Bookings Count as a tooltip.
2. **Text box** with 3 recommendations.

Save as `dashboard/hotel_cancellation.pbix` and screenshot each page into `images/`.

## Week 3 — Tell the story and publish

### Day 13 — The one-page summary

```
Hotel Booking Cancellation & Revenue Risk Analysis

The question: How much do cancellations cost, which bookings cancel, and what should we change?

What I found:
  1. [X]% of bookings cancel ([Y]% City, [Z]% Resort) — €[V] of booked revenue at risk.
  2. Risk rises with lead time: [A]% for bookings made 6+ months ahead vs [B]% within a week.
  3. [Segment] is the riskiest channel at [C]%; guests with special requests or past stays cancel far less.
  Worth checking: Non-refundable bookings show [D]% cancellation, mostly from [segment/country].

What I recommend:
  1. Ask for a deposit on [segment] bookings made 90+ days ahead.
  2. Overbook by a small, tested % only for that segment in high-cancel months.
  3. Send a pre-arrival engagement email (room preferences, parking) — engaged guests cancel less.

Limits: revenue at risk ≠ revenue lost (rooms are resold); 2015–2017 data; two hotels only.
```

### Day 14 — README and GitHub

Use the README template from the [Start here guide](../../START-HERE.md). Upload the Excel workbook (with your pivots), the .pbix, images, data notes and summary to a GitHub repo named `hotel-cancellation-analysis`.

### Day 15 — LinkedIn and practice

Post it with the watch-list matrix as the image. Practise the 60-second story.

## You're on track if…

- Your overall cancellation rate is in the high 30s %.
- The City Hotel and Resort Hotel show different rates.
- Cancel rate generally climbs from short to long lead times.

## Common mistakes I'd catch in a review

- Combining both hotels into one number.
- Leaving "NA" as text in children, which breaks total guests.
- Calling it "revenue lost" instead of "revenue at risk".
- Reporting a rate without the number of bookings behind it.
- Recommending "deposits for everyone" instead of for the risky segment.

## Tell the story

### Your 60-second interview explanation

> "My project is a hotel booking cancellation and revenue risk analysis. A hotel's revenue manager said over a third of bookings were cancelling. I took 119,000 real bookings and cleaned them in Power Query — text 'NA' values, month names, bookings with zero guests or impossible prices. Using pivot tables and Power BI, I found cancellations put about \[X\] euros of bookings at risk, that bookings made far in advance and through \[segment\] cancel the most, and that guests with special requests rarely cancel. I also dug into a strange result — non-refundable bookings cancelling a lot — and traced it to \[segment\]. I recommended deposits and careful overbooking only for the risky segment."

### Resume bullets

- "Hotel Cancellation & Revenue Risk Analysis: cleaned and analysed 119k hotel bookings in Excel Power Query and Power BI; quantified €\[X\] of booked revenue at risk from a \[Y\]% cancellation rate."
- "Built a segment × lead-time cancellation watch list and recommended a targeted deposit and overbooking policy for the highest-risk bookings (\[Z\]% cancel rate)."

### Questions interviewers will ask

- "Is all cancelled revenue lost?" — No; some rooms are resold. That's why I called it revenue at risk.
- "Why split by hotel?" — City and resort hotels serve different guests; combining hides both.
- "How would you predict cancellations?" — Start with the watch-list rule; later a classification model using lead time, segment, deposit and requests.


---

← [Back to all projects](../../README.md) · [Start here guide](../../START-HERE.md)
