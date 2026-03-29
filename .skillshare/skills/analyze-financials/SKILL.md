---
name: analyze-financials
description: Fetch financial statements from SEC 10-K filings and Yahoo Finance for a BusMgmtBenchmarks retail company, compare all sources side by side, detect anomalies (especially SGA composite line items, restatements, and balance sheet mismatches), and produce reconciled values ready for the Dolt database. Use when validating or adding financial data for any company tracked in the BusMgmtBenchmarks project. Triggered by commands like "/analyze-financials TICKER YEAR" or requests to fetch, check, or validate financials for a company in the project.
---

# analyze-financials

Fetch, compare, and reconcile financial data for a BusMgmtBenchmarks retail company across multiple sources, then produce DB-ready reconciled values.

## Inputs

`/analyze-financials TICKER YEAR`

- `TICKER` — stock ticker (e.g. TRR, WMT, M)
- `YEAR` — fiscal year label **as stored in the Dolt DB** (e.g. 2024)

### Dolt Year Convention

The Dolt DB `year` field follows the **fiscal year label**, not the calendar year of the fiscal year-end date. For retailers whose fiscal year ends in January or February, the year-end date falls in the calendar year *after* the Dolt label:

| Dolt `year` | Example reportDate | Company |
|-------------|-------------------|---------|
| 2023 | 2024-02-03 | Macy's |
| 2023 | 2024-02-03 | Walmart |
| 2024 | 2025-01-31 | Macy's |

**Rule:** `YEAR` passed to this skill = the Dolt `year` label. For retailers with Jan/Feb fiscal year-ends, the actual `reportDate` will be in calendar year `YEAR + 1`.

For calendar-year companies (e.g. fiscal year ends Dec 31), `reportDate` is in the same calendar year as the Dolt label.

## Step 1 — Look up company metadata

Query the Dolt database to get company metadata by ticker symbol:

```sql
SELECT company, CIK, display_name, ticker_symbol
FROM company_info
WHERE ticker_symbol = '{TICKER}'
```

Use `db_string: calvinw/BusMgmtBenchmarks/main`.

From the result, use:
- `company` — the exact `company_name` as stored in the DB (needed for financials query)
- `CIK` — needed for the SEC fetch
- `display_name` — for display in the report header

If no row is returned, ask the user to confirm the ticker. If CIK is NULL, the company has no SEC filing (non-US company) — skip the SEC fetch and use Yahoo only.

## Step 2 — Fetch all sources in parallel

Run these three fetches simultaneously:

| Source | Tool |
|--------|------|
| SEC 10-K | `mcp__mcp-sec-10ks__process_financial_data_from_sec(company_name, YEAR, cik)` |
| Yahoo Finance | `mcp__mcp-yfinance-10ks__process_financial_data_from_yahoo(company_name, ticker)` |
| Dolt DB (existing row) | `mcp__claude_ai_Dolt_Database_MCP__read_query` → `SELECT * FROM financials WHERE company_name = '...' AND year = YEAR` on `calvinw/BusMgmtBenchmarks/main` |

## Step 2b — Verify the correct fiscal period column

Both the SEC and Yahoo MCP tools return **multiple years of data** in a table with date column headers. After fetching, you must identify which column corresponds to the Dolt `YEAR` label before extracting any values.

**How to select the correct column:**

1. Determine the expected `reportDate` for this company and Dolt `YEAR`:
   - If the company has an existing Dolt row (from the Dolt fetch above), use its `reportDate` as the target.
   - If no existing row, derive the expected reportDate from the company's fiscal year pattern (see company-notes.md). For Jan/Feb year-end retailers, the reportDate for Dolt `year=N` will be in calendar year `N+1` (e.g., Dolt `year=2023` → reportDate ~Feb 2024).

2. In the SEC income statement/balance sheet, find the **column whose header date matches the expected reportDate**. This is typically the leftmost (most recent) column in a new filing, but may be a prior-year comparative column if the filing year differs.

3. In the Yahoo Finance tables, find the **column whose header date matches the expected reportDate**.

4. **Cross-check:** Confirm the selected SEC column date and Yahoo column date agree with the expected reportDate. If they disagree by more than a few days (e.g., Jan 28 vs Jan 31 is acceptable; Jan 28 vs Jan 28 of a different year is `[ERROR]`), flag `[WARNING]` and investigate.

**Example — Macy's `/analyze-financials M 2023`:**
- Dolt `year=2023` → expected reportDate ~Feb 2024
- SEC filing (filed ~Mar 2024) returns columns: `2024-02-03 | 2023-01-28 | 2022-01-29`
- Select column `2024-02-03` (the one ending in calendar year 2024)
- Yahoo returns columns: `2025-01-31 | 2024-01-31 | 2023-01-31 | 2022-01-31`
- Select column `2024-01-31` (closest match to the SEC's 2024-02-03)
- **Do NOT select the `2023-01-28` SEC column** — that would be Dolt `year=2022` data

## Step 3 — Extract the 13 standard fields

All values in **thousands of dollars**. Extract from **the verified fiscal period column** identified in Step 2b:

| Field | Notes |
|-------|-------|
| Net Revenue | |
| Cost of Goods | Positive value |
| Gross Margin | Revenue − COGS |
| SGA | Most error-prone — see anomaly rules |
| Operating Profit | Can be negative |
| Net Profit | Can be negative |
| Inventory | NULL for pure marketplace companies |
| Current Assets | |
| Total Assets | |
| Current Liabilities | |
| Liabilities | Total Assets − Total SE |
| Total Shareholder Equity | Can be negative |
| Total Liabilities and Shareholder Equity | Must equal Total Assets |

Also extract `reportDate` (fiscal year-end date, e.g. `2024-12-31`).

## Step 4 — Run anomaly detection

Read `references/anomaly-rules.md` now. Apply all rules.
Read `references/company-notes.md` and check for any entry matching this company.

Flag every issue as `[WARNING]` (investigate) or `[ERROR]` (must resolve before inserting).

## Step 5 — Side-by-side comparison table

Present a table with columns: SEC | Yahoo | Dolt (current) | Recommended.
Mark cells where sources disagree with `*`.

## Step 6 — Reconciled recommendation

For each field state:
- Recommended value and which source it comes from
- Any adjustment made (especially SGA composite construction)
- Whether the current Dolt value differs and would be overwritten

## Step 7 — Signal readiness

End with:

> **Analysis complete.** Run `/insert-financials {TICKER} {YEAR}` to write these values to the database.

List any unresolved flags for the user to review before inserting.

## Step 8 — Save report to file

After displaying the full analysis to the user, write the complete report as a markdown file:

**Path:** `reports/{TICKER}-{YEAR}.md`

The report file must contain:

```
# {Company Name} ({TICKER}) — FY{YEAR} Financial Analysis

**Generated:** {today's date}
**Source:** /analyze-financials skill

---
```

Followed by all content from Steps 4–7 in full: anomaly detection table, side-by-side comparison table, reconciled recommendation, and the readiness signal (including any unresolved flags).

After writing the markdown file, tell the user:
> Report saved to `skills/reports/{TICKER}-{YEAR}.md`.
> To generate a styled HTML version for sharing, run:
> `bash skills/reports/generate-html-report.sh {TICKER} {YEAR}`
> After committing and pushing the HTML, it will be published at:
> `https://calvinw.github.io/BusMgmtBenchmarks/reports/{TICKER}-{YEAR}.html`

## References

- **`references/anomaly-rules.md`** — SGA composite rules, balance sheet checks, gross margin benchmarks, restatement logic. Read in Step 4.
- **`references/company-notes.md`** — Per-company quirks. Check in Step 4 for the company being analyzed.
