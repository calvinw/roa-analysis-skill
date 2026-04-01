# ROA Analysis Skill

A GitHub Codespace for business and retail management students to compare companies using the ROA (Return on Assets) DuPont breakdown.

## What This Does

Run a single command and get a side-by-side financial comparison of two retail companies — including Net Profit Margin %, Asset Turnover, and ROA % — pulled live from a shared database, with a plain-English interpretation written for business students.

## The Skill

| Command | What it does |
|---------|-------------|
| `/roa-analysis TICKER1 TICKER2 YEAR` | Compare two companies side by side using the ROA DuPont breakdown |

**Examples:**
- `/roa-analysis WMT M 2024` — Walmart vs Macy's, fiscal year 2024
- `/roa-analysis COST TGT 2023` — Costco vs Target, fiscal year 2023
- `/roa-analysis WMT COST 2024` — Walmart vs Costco, fiscal year 2024

The skill queries the database for both companies, builds a financial summary table, calculates the DuPont components, and writes a plain-English interpretation of what the numbers reveal about each company's business model.

Reports are automatically saved to the `reports/` folder.

## The ROA Breakdown

ROA (Return on Assets) is calculated as:

**Net Profit Margin % × Asset Turnover = ROA %**

- **Net Profit Margin %** — for every dollar of sales, how many cents does the company keep as profit?
- **Asset Turnover** — for every dollar of assets the company owns, how many dollars of sales does it generate?
- **ROA %** — how effectively does the company turn what it owns into profit?

Two companies can reach the same ROA through very different strategies. Walmart runs on thin margins and massive sales volume. A specialty retailer might have higher margins but slower turnover. The DuPont breakdown shows you which path each company is taking.

## Getting Started

Open in GitHub Codespaces — everything is set up automatically. Then open Claude Code and type:

```
/roa-analysis WMT M 2024
```

## Documentation

- [AGENTS.md](AGENTS.md) — How the skill works, database schema, and how to edit or test the skill
- [CLAUDE.md](CLAUDE.md) — Claude Code behavior rules and how to explain ROA to students
- [SkillEditor.md](SkillEditor.md) — Role instructions for editing the skill file
- [SkillTester.md](SkillTester.md) — Role instructions for testing skill changes
