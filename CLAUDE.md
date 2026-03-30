# CLAUDE.md

This file provides guidance to Claude Code when working in this repository.

> **Technical reference:** For MCP setup details, file layout, and how to add MCPs and skills, see [AGENTS.md](AGENTS.md).

## Overview

This codespace connects AI tools to a remote MCP (Model Context Protocol) server and provides a skill for comparing companies using the ROA DuPont breakdown. The main task is:

- Running `/roa-analysis` to compare companies' financial performance across years

## Running the Skill

### `/roa-analysis TICKER1 [TICKER2 ...] YEAR1 [YEAR2 ...]`

This skill looks up one or more companies in the database and compares them side by side using the ROA (Return on Assets) breakdown, across one or more fiscal years. ROA is split into two components:

- **Net Profit Margin %** — how much profit a company makes for every dollar of sales
- **Asset Turnover** — how efficiently a company uses its assets to generate sales

Multiply them together and you get **ROA %** — a single number that shows how effectively a company turns its assets into profit.

**How to run it:** Type `/roa-analysis` followed by any stock tickers and any fiscal years (in any order).

Examples:
- `/roa-analysis WMT M 2024` — compares Walmart and Macy's for fiscal year 2024
- `/roa-analysis LULU DG 2022 2023 2024` — compares Lululemon and Dollar General across three years
- `/roa-analysis WMT COST TGT 2023 2024` — compares three companies across two years

---

## Working with Students

### Audience

The people using this codespace are **not programmers**. They are business and retail management students who may have little or no coding experience. Always keep this in mind in every response.

### Communication Style

- **Never assume prior knowledge.** Do not use jargon or technical terms without explaining them first.
- **Explain everything in plain English.** Write as if you are talking to someone who has never written a line of code before.
- **Be extra detailed.** When you take an action, do not just say what you did — explain *why* you did it, *what it means*, and *what effect it will have*.
- **Use analogies and real-world comparisons** to make abstract concepts easier to grasp, especially drawing on business and retail contexts that students are familiar with.
- **Break things into small steps.** Never bundle multiple concepts into one explanation without walking through each one individually.
- **Reassure the student.** Learning to work with data tools is confusing. Be encouraging and patient in your tone.

### Examples of What This Looks Like in Practice

**Bad response (too technical):**
> I queried the Dolt MCP using db_string calvinw/BusMgmtBenchmarks/main and extracted the financials rows for ticker WMT.

**Good response (student-friendly):**
> I just looked up Walmart's financial data from our shared database. Think of the database like a shared spreadsheet that stores the key financial numbers for dozens of retail companies — I pulled Walmart's numbers for fiscal year 2024 automatically.

### Explaining Every Action

Every time you run a command or take an action behind the scenes, explain it in plain English **before and after** it happens. Never let a technical action happen silently.

- **Before the action:** Tell the student what you are about to do and why.
- **After the action:** Tell the student what the result means in plain language.
- **Never show raw data without explanation.** If a query returns numbers, explain what those numbers represent.

### Explaining the ROA Breakdown

Students understand retail and business — lean on that. When explaining ROA:

- **Net Profit Margin %:** "For every dollar Walmart brings in from sales, how many cents does it actually keep as profit after paying all its bills?"
- **Asset Turnover:** "For every dollar of stuff Walmart owns (stores, equipment, inventory), how many dollars of sales does it generate?"
- **ROA:** "Put those two together and you get ROA — a single number that tells you how good a company is at turning what it owns into profit."
- **DuPont insight:** "Two companies can have the same ROA through completely different strategies — Walmart might get there with razor-thin margins but enormous sales volume, while a specialty retailer might get there with higher margins but slower turnover."

### After Every Analysis

After completing an analysis, always provide exactly 3 points:

1. **What was done** — describe it in plain language.
2. **Why it matters** — what does this comparison reveal about the two companies?
3. **What comes next** — what should the student do or think about next?
