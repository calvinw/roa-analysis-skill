# AGENTS.md — Working in BusMgmtBenchmarks

This document helps agents work effectively in the `bus-mgmt-benchmarks-dolt-db` repository.

## Project Overview

**BusMgmtBenchmarks** is a financial benchmarking database for retail companies, hosted as a Dolt database at [DoltHub](https://www.dolthub.com/). This repository is a GitHub Codespace setup that provides:

1. **Dolt Database Access** — Read/write to `calvinw/BusMgmtBenchmarks/main` via MCP (Model Context Protocol)
2. **Financial Data Pipeline** — Two AI skills to fetch, validate, and insert financial data for retail companies
3. **Multi-Tool Support** — All AI tools (Claude Code, OpenCode, Gemini CLI, Copilot, Crush) pre-configured with Dolt and financial data MCP servers

**Key URLs:**
- Dolt database: `https://www.dolthub.com/repositories/calvinw/BusMgmtBenchmarks`
- MCP server: `https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse`
- Report publication: `https://calvinw.github.io/BusMgmtBenchmarks/reports/`

---

## MCP Servers & Tools

All AI tools connect to **three MCP servers**:

| Server | Purpose | Config Location |
|--------|---------|-----------------|
| **dolt** | Read/write Dolt database tables | `.crush.json`, `configs/mcp/claude-settings.json` |
| **mcp-yfinance-10ks** | Fetch financial statements from Yahoo Finance | `.crush.json`, `configs/mcp/claude-settings.json` |
| **mcp-sec-10ks** | Fetch financial statements from SEC 10-K filings | `.crush.json`, `configs/mcp/claude-settings.json` |

### Using MCP Servers

**In Crush:** Tools are already available. Use them directly:
```bash
mcp_dolt_read_query(sql="SELECT * FROM company_info", db_string="calvinw/BusMgmtBenchmarks/main")
mcp_mcp_yfinance_10ks_process_financial_data_from_yahoo(company_name="Walmart", ticker_symbol="WMT")
mcp_mcp_sec_10ks_process_financial_data_from_sec(company_name="Walmart", year=2024, cik="104169")
```

**In Claude Code / other tools:** Use the UI chat interface — MCPs are pre-configured.

---

## Core Skills & Workflows

### 1. `/analyze-financials TICKER YEAR`

**Purpose:** Fetch financial statements from SEC and Yahoo Finance, compare them side-by-side, detect anomalies, and produce reconciled values.

**Full workflow:** See `.claude/skills/analyze-financials/SKILL.md`

**Key inputs:**
- `TICKER` — stock ticker (e.g., `WMT`, `M`, `TRR`)
- `YEAR` — fiscal year (e.g., `2024`)

**Key outputs:**
1. Reconciled financial data (13 fields) ready for insertion
2. Markdown report saved to `reports/{TICKER}-{YEAR}.md`
3. Signal to proceed with `/insert-financials` if all checks pass

**Example:**
```
/analyze-financials WMT 2024
```

### 2. `/insert-financials TICKER YEAR`

**Purpose:** Generate a SQL `REPLACE INTO` statement to insert reconciled financial data into the Dolt database.

**Full workflow:** See `.claude/skills/insert-financials/SKILL.md`

**Key inputs:**
- Must be run AFTER `/analyze-financials` in the same session
- Uses reconciled values from analyze-financials output

**Key outputs:**
1. SQL file written to `extract/2026/inserts/{TICKER}_{YEAR}_insert.sql`
2. Instructions for manually applying to local Dolt clone
3. Does NOT connect to or write to any database — purely generates a file

**Example:**
```
/insert-financials WMT 2024
```

---

## Database Schema

The Dolt database `calvinw/BusMgmtBenchmarks/main` contains (at minimum):

### `company_info` table
```sql
SELECT company, CIK, display_name, ticker_symbol
FROM company_info
WHERE ticker_symbol = 'WMT'
```

**Fields used in analyze-financials:**
- `company` — exact company name as stored in DB (matches `company_name` in financials table)
- `CIK` — SEC Central Index Key (NULL for non-US companies)
- `display_name` — formatted name for reports
- `ticker_symbol` — stock ticker

### `financials` table
```sql
SELECT * FROM financials 
WHERE company_name = 'Walmart' AND year = 2024
```

**13 required fields** (all in thousands of dollars):

| Field | Type | Notes |
|-------|------|-------|
| company_name | STRING | Exact match of `company_info.company` |
| year | INT | Fiscal year (e.g., 2024) |
| reportDate | STRING | Fiscal year-end date (e.g., '2024-12-31') |
| Net Revenue | INT | Annual total net sales |
| Cost of Goods | INT | Positive value |
| Gross Margin | INT | Calculated: Revenue − COGS |
| SGA | INT | Selling, General & Administrative |
| Operating Profit | INT | Can be negative |
| Net Profit | INT | Bottom line; can be negative |
| Inventory | INT or NULL | NULL for marketplace companies |
| Current Assets | INT | |
| Total Assets | INT | |
| Current Liabilities | INT | |
| Liabilities | INT | Calculated: Total Assets − Total Shareholder Equity |
| Total Shareholder Equity | INT | Can be negative |
| Total Liabilities and Shareholder Equity | INT | Must equal Total Assets |

---

## Financial Data Rules & Anomaly Detection

### Critical Rules

Read `.claude/skills/analyze-financials/references/anomaly-rules.md` for complete details.

**SGA Composite (most error-prone):**
1. **Rule 1** — Add Marketing to SGA if both reported separately (traditional retailers)
2. **Rule 2** — EXCLUDE platform/ops-tech costs for marketplace companies (e.g., TheRealReal's `real_OperationsAndTechnologyExpense`)
3. **Rule 3** — Don't trust Yahoo SGA if it equals Total Operating Expenses (likely aggregated)
4. **Rule 4** — Sum G&A + Selling if no combined tag exists

**Balance Sheet Identity [ERROR if fails]:**
- `Total Assets` must equal `Total Liabilities and Shareholder Equity` (±$1K rounding)

**Derived Fields (calculate; don't trust sources):**
- `Gross Margin` = Net Revenue − Cost of Goods
- `Liabilities` = Total Assets − Total Shareholder Equity

**Restatement Rule:**
- Always use the most recent filing version for any given year
- If newer filing contains restated prior-year numbers, flag as `[WARNING]` and note discrepancies

**Inventory Rule:**
- Set `Inventory = NULL` for pure marketplace/consignment companies only (e.g., TheRealReal, ASOS marketplace)
- For traditional retailers, NULL or zero is `[ERROR]` — investigate

### Company-Specific Patterns

See `.claude/skills/analyze-financials/references/company-notes.md` for per-company quirks.

**Example — TheRealReal (TRR):**
- Marketplace company: set `Inventory = NULL`
- SGA = SGA line + Marketing line, but EXCLUDE platform costs
- FY2024: Correct SGA = $243,000K (wrong value if including ops costs: $503,564K)
- Negative shareholder equity is expected

**Example — Macy's (M):**
- Department store: gross margin ~35–45%
- Fiscal year ends late January (not Dec 31)
- Single combined SGA line — use directly without adjustment

**Example — Walmart (WMT):**
- Discount retailer: gross margin ~10–30%
- Fiscal year ends late January
- Single combined SGA line

---

## File Organization

```
.
├── README.md                          # Project overview
├── AGENTS.md                          # This file
├── .crush.json                        # Crush MCP config
├── configs/
│   ├── codex/
│   │   └── config.toml                # Source-of-truth Codex config
│   └── mcp/                           # Source-of-truth MCP config files
│       ├── claude-settings.json       # Claude Code & Codex MCP endpoint config
│       ├── copilot-mcp-config.json    # GitHub Copilot MCP config
│       ├── gemini-settings.json       # Gemini CLI MCP config
│       └── opencode.json              # OpenCode MCP config
├── .devcontainer/
│   ├── devcontainer.json              # Codespace config
│   └── post-create.sh                 # Auto-setup MCP servers on boot
├── .claude/                           # Generated by setup-mcps.sh (gitignored)
├── .copilot/                          # Generated by setup-mcps.sh (gitignored)
├── .opencode/                         # Generated by setup-mcps.sh (gitignored)
├── .gemini/                           # Generated by setup-mcps.sh (gitignored)
├── .skillshare/
│   ├── config.yaml                    # Skillshare (cross-tool skill sharing) config
│   └── skills/                        # Replicated skills for non-Crush tools
├── reports/                           # Generated financial reports
│   ├── M-2020.md                      # Example: Macy's FY2020
│   ├── M-2021.md
│   ├── WMT-2022.md
│   └── ...
└── extract/2026/inserts/              # Generated SQL files (created by /insert-financials)
    ├── WMT_2024_insert.sql
    └── ...
```

---

## Common Workflows

### Workflow 1: Validate & Add Financial Data for a Company

1. **Trigger:** User asks to fetch/validate/add financials for a company
2. **Run:** `/analyze-financials TICKER YEAR`
   - Fetches SEC 10-K and Yahoo Finance side-by-side
   - Applies anomaly detection rules
   - Produces reconciled values
   - Saves report to `reports/{TICKER}-{YEAR}.md`
3. **Review:** Check flags and reconciliation table
4. **Insert:** If ready, run `/insert-financials TICKER YEAR`
   - Generates SQL file to `extract/2026/inserts/{TICKER}_{YEAR}_insert.sql`
5. **Apply (manual):** User applies SQL to their local Dolt clone:
   ```bash
   cd /path/to/dolt/BusMgmtBenchmarks
   dolt sql < /path/to/extract/2026/inserts/{TICKER}_{YEAR}_insert.sql
   dolt diff && dolt commit -am "Add {company_name} FY{YEAR} financials" && dolt push
   ```

### Workflow 2: Debug Anomaly in Financial Data

1. **Look up the company** in `company-notes.md` for known quirks
2. **Check anomaly rules** in `anomaly-rules.md` for the relevant rule (SGA, balance sheet, inventory, etc.)
3. **Query the database** to inspect existing data:
   ```sql
   SELECT * FROM financials WHERE company_name = 'TheRealReal' AND year = 2024
   ```
4. **Review the filing** (SEC or Yahoo) for the raw values
5. **Apply the rule** and reconcile
6. **Add notes** to `company-notes.md` if a new pattern emerges

### Workflow 3: Check if a Company Exists in the Database

```sql
SELECT company, ticker_symbol, CIK FROM company_info WHERE ticker_symbol = 'WMT'
```

If CIK is NULL, the company is non-US and has no SEC filing — skip SEC fetch in analyze-financials.

---

## Key Gotchas & Patterns

### Gotcha 1: SGA is Composite — Never Trust a Single Source

SGA (Selling, General & Administrative) is reported differently by different companies and sources. The analyze-financials skill handles four common patterns, but always:

1. Compare SEC and Yahoo side-by-side
2. Apply Rule 1–4 from `anomaly-rules.md`
3. Flag warnings if sources disagree
4. Check `company-notes.md` for known patterns

### Gotcha 2: Yahoo Finance Data is Limited

- Yahoo typically provides **only the last 4 years** of data (fiscal years ending ~Jan–Dec 2022–2025)
- Older years (e.g., FY2020) are not available from Yahoo
- This is expected and flagged in analyze-financials output

### Gotcha 3: Fiscal Year Dates Are Company-Specific

- Most US retailers have **fiscal year ends in late January** (not Dec 31)
- Examples: Walmart, Macy's, Target (FY2024 ends ~Jan 31, 2024)
- `reportDate` must reflect the actual fiscal year-end, not a rounded date

### Gotcha 4: Non-US Companies Have No SEC Data

Companies listed in `company-notes.md` (Louis Vuitton, H&M, Adidas, etc.) are non-US:
- `CIK` is NULL in `company_info`
- Skip the SEC fetch; use Yahoo only
- Flag in the analysis that SEC is unavailable

### Gotcha 5: Negative Equity is Valid (But Must Be Confirmed)

Some companies (e.g., TheRealReal, heavily leveraged retailers) have **negative Total Shareholder Equity**. This is not an error — it reflects high debt relative to assets. Always flag it as `[WARNING]` and confirm before inserting.

### Gotcha 6: Inventory = NULL for Marketplace Companies Only

- **Pure marketplace/consignment companies** (TheRealReal, ASOS marketplace segment) carry no physical inventory → set `Inventory = NULL`
- **Traditional retailers** must have a positive inventory value → NULL or zero is `[ERROR]`

### Gotcha 7: Balance Sheet Identity is Non-Negotiable

`Total Assets` must equal `Total Liabilities and Shareholder Equity` (within ±$1K rounding). If they don't match, the extraction from the filing was incorrect — **do not insert** until resolved.

### Gotcha 8: Restatement vs. Original Filing

Later 10-K filings often restate prior-year numbers (e.g., the 2024 10-K contains FY2023 comparatives that differ from the 2023 10-K). Always use the most recent filing version.

---

## Commands & Tools

### Crush Commands

**Query the database:**
```bash
crush query "SELECT * FROM company_info LIMIT 5" --db calvinw/BusMgmtBenchmarks/main
```

**Fetch from Yahoo Finance:**
```bash
crush fetch yahoo WMT 2024
```

**Fetch from SEC:**
```bash
crush fetch sec 104169 2024
```

### Git Workflow

**Check status:**
```bash
cd /workspaces/bus-mgmt-benchmarks-dolt-db && git status
```

**View recent commits:**
```bash
git log --oneline -10
```

**Commit generated SQL files (after testing in local Dolt clone):**
```bash
git add extract/2026/inserts/ reports/
git commit -m "Add financial data for {TICKER} FY{YEAR}"
```

### Setup

On boot, the `.devcontainer/post-create.sh` script:
1. Installs Skillshare (cross-tool skill sharing)
2. Configures MCP servers for all AI tools
3. Symlinks MCP configs to tool-specific directories
4. Links Codex config from `configs/codex/config.toml`
5. Registers Claude and Codex MCP servers from `configs/mcp/claude-settings.json`

To manually re-run setup:
```bash
bash .devcontainer/post-create.sh
```

---

## Testing & Validation

### Validate a Financial Data Row

Before inserting, verify:

1. **Identity check:** `Total Assets == Total Liabilities + Shareholder Equity` (±$1K)
2. **Gross Margin sanity:** Is it within the range for this company's retail segment?
3. **Inventory logic:** Marketplace companies should have `Inventory = NULL`; others must have positive inventory
4. **Negative equity:** If present, confirm it's expected (e.g., TheRealReal)
5. **Negative net profit:** If present, confirm it's explained (e.g., restructuring charge, impairment)

### Query After Inserting

After running `/insert-financials` and applying the SQL to your local Dolt clone, verify:

```sql
-- Confirm the new row exists
SELECT * FROM financials WHERE company_name = 'Walmart' AND year = 2024

-- Check balance sheet identity
SELECT company_name, year, 
       `Total Assets` - (`Liabilities` + `Total Shareholder Equity`) AS imbalance
FROM financials
WHERE company_name = 'Walmart' AND year = 2024
-- Should be ≤ 1 (rounding)
```

---

## Reference Files to Read

- **`.claude/skills/analyze-financials/SKILL.md`** — Complete step-by-step analyze-financials workflow
- **`.claude/skills/analyze-financials/references/anomaly-rules.md`** — All SGA rules, balance sheet checks, restatement logic
- **`.claude/skills/analyze-financials/references/company-notes.md`** — Per-company patterns and quirks
- **`.claude/skills/insert-financials/SKILL.md`** — Complete step-by-step insert-financials workflow
- **`.devcontainer/post-create.sh`** — Environment, Codex config, MCP setup, and Skillshare configuration
- **`.crush.json`** — MCP server URLs for Crush
- **`configs/mcp/claude-settings.json`** — MCP server URLs for Claude Code and Codex
- **`configs/codex/config.toml`** — Source-of-truth Codex CLI configuration
- **`configs/mcp/`** — Source-of-truth MCP configs for all tools (Copilot, OpenCode, Gemini)

---

## Quick Checklist for New Agents

- [ ] Read this file (AGENTS.md) to understand the project
- [ ] Review `.claude/skills/analyze-financials/references/anomaly-rules.md` if working with financial data
- [ ] Check `.claude/skills/analyze-financials/references/company-notes.md` for the specific company
- [ ] Verify MCP servers are available: `.crush.json`, `configs/mcp/` are checked in
- [ ] Use `/analyze-financials TICKER YEAR` to fetch and validate data
- [ ] Use `/insert-financials TICKER YEAR` to generate SQL (after analyze-financials)
- [ ] Apply the SQL to your local Dolt clone manually (skill doesn't write to DB)
- [ ] Verify balance sheet identity and sanity checks before inserting
- [ ] Save reports to `reports/{TICKER}-{YEAR}.md`
- [ ] Commit new data to git (don't push to remote without explicit permission)

---

## Contact & Support

- **Dolt Database:** `calvinw/BusMgmtBenchmarks` on [DoltHub](https://www.dolthub.com/)
- **MCP Servers:** Hosted at `https://bus-mgmt-databases.mcp.mathplosion.com/`
- **Generated Reports:** Published at `https://calvinw.github.io/BusMgmtBenchmarks/reports/`
