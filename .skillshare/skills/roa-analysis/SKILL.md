---
name: roa-analysis
description: Compare one or more retail companies across one or more years using the ROA (Return on Assets) DuPont breakdown — Net Profit Margin % × Asset Turnover = ROA. Queries the Dolt database and displays comparison tables with interpretation. Triggered by "/roa-analysis TICKER1 [TICKER2 ...] YEAR1 [YEAR2 ...]".
---

# roa-analysis

Compare companies using the DuPont ROA breakdown, across one or more years.

## Inputs

`/roa-analysis TICKER1 [TICKER2 ...] YEAR1 [YEAR2 ...]`

Arguments can be given in any order. Any 4-digit number is treated as a year; everything else is treated as a stock ticker.

Examples:
- `/roa-analysis LULU DG 2024` — two companies, one year
- `/roa-analysis LULU DG 2022 2023 2024` — two companies, three years
- `/roa-analysis WMT COST TGT 2023 2024` — three companies, two years

## Step 1 — Parse inputs

Split the arguments into two lists:
- **Tickers** — any token that is NOT a 4-digit number
- **Years** — any token that IS a 4-digit number

If no tickers or no years are found, tell the user the correct format and stop.

## Step 2 — Look up all companies

For each ticker, query:

```sql
SELECT company, display_name, ticker_symbol
FROM company_info
WHERE ticker_symbol = '{TICKER}'
```

Use `db_string: calvinw/BusMgmtBenchmarks/main`.

If any ticker returns no row, tell the user that company is not in the database and stop.

## Step 3 — Fetch financial data

For ALL companies and ALL years, fetch data in a single query:

```sql
SELECT company_name, year, reportDate,
       `Net Revenue`,
       `Cost of Goods`,
       `Gross Margin`,
       `SGA`,
       `Operating Profit`,
       `Net Profit`,
       `Total Assets`
FROM financials
WHERE company_name IN ('{company1}', '{company2}', ...)
  AND year IN ({YEAR1}, {YEAR2}, ...)
ORDER BY year, company_name
```

If data is missing for any company/year combination, note it in the output but continue with available data.

## Step 4 — Calculate ROA components

For each company × year combination, compute:

| Metric | Formula |
|--------|---------|
| Net Profit Margin % | Net Profit ÷ Net Revenue × 100 |
| Asset Turnover | Net Revenue ÷ Total Assets |
| ROA % | Net Profit Margin % × Asset Turnover |

Round all values to two decimal places.

## Step 5 — Display tables

### Layout when there is ONE year

Show a single side-by-side table with companies as columns (same as the original two-company format).

**Financial Summary ($ thousands)**

| Metric | {Company 1} | {Company 2} | ... |
|--------|------------|------------|-----|
| Net Revenue | | | |
| Cost of Goods | | | |
| Gross Margin | | | |
| SGA | | | |
| Operating Profit | | | |
| Net Profit | | | |
| Total Assets | | | |

**ROA Breakdown**

| Metric | {Company 1} | {Company 2} | ... |
|--------|------------|------------|-----|
| Net Profit Margin % | | | |
| × Asset Turnover | | | |
| = ROA % | | | |

### Layout when there are MULTIPLE years

Show one section per year, each with its own side-by-side table (same format as above). Label each section clearly:

```
## Fiscal Year {YEAR}
```

Then, after all the per-year tables, show a **Trend Summary** — one table per ROA metric showing how each company changed over time:

**Net Profit Margin % Over Time**

| Year | {Company 1} | {Company 2} | ... |
|------|------------|------------|-----|
| 2022 | | | |
| 2023 | | | |
| 2024 | | | |

**Asset Turnover Over Time**

| Year | {Company 1} | {Company 2} | ... |
|------|------------|------------|-----|
| 2022 | | | |
| 2023 | | | |
| 2024 | | | |

**ROA % Over Time**

| Year | {Company 1} | {Company 2} | ... |
|------|------------|------------|-----|
| 2022 | | | |
| 2023 | | | |
| 2024 | | | |

## Step 6 — Interpret the results

After the tables, write a plain-English interpretation covering:

1. **Overall winner** — which company has the highest ROA, and what does that mean?
2. **Margin story** — which company is more profitable per dollar of sales?
3. **Turnover story** — which company uses its assets more efficiently?
4. **Trend** (if multiple years) — is either company improving or declining over time? What might explain that?
5. **Business model insight** — what does the DuPont breakdown reveal about how each company makes money? (e.g. premium margins vs high-volume low-margin)

Keep the interpretation in plain English suitable for a business student with no finance background.
