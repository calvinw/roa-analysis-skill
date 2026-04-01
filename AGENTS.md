# AGENTS.md

All guidance for working in this repository — including tone, communication style, and how to help students — lives in [CLAUDE.md](CLAUDE.md).

Read that file before doing anything else.

---

## Working on the Skill

The skill file lives at `.skillshare/skills/roa-analysis/SKILL.md`. This is where you read and edit it.

**The `.skillshare/` folder is for distributing finished skills — not works in progress.** Do not run `scripts/sync-skills.sh` while a skill is still being developed or tested. Only sync when the skill is complete and ready to be published.

### How to work on the skill

- **To read or edit:** Open `.skillshare/skills/roa-analysis/SKILL.md` directly.
- **To invoke it during a session:** Explicitly ask the agent to load the skill file. Do not expect it to be active automatically while you're working on it.
- **To test it properly:** Start a fresh session, then ask the agent to load the skill file.
- **To publish it when done:** Run `scripts/sync-skills.sh` to distribute it.

### Reports

When the skill runs successfully, it saves a markdown report to the `reports/` directory. Filenames follow this pattern:

```
reports/roa-analysis-{TICKER1}-{TICKER2}-{YEAR}.md
```

Students can find all past analyses there.

---

## MCP Server

All AI tools connect to the MCP server defined in `configs/mcp-urls.conf`:

| Server | URL | Purpose |
|--------|-----|---------|
| **dolt** | `https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse` | Read/write the BusMgmtBenchmarks Dolt database |

To add more MCP servers, add a line to `configs/mcp-urls.conf` in `name=url` format. All setup scripts read this file automatically.

### Using the Dolt MCP

```
mcp__dolt__read_query(db_string="calvinw/BusMgmtBenchmarks/main", sql="SELECT * FROM company_info")
mcp__dolt__list_tables(db_string="calvinw/BusMgmtBenchmarks/main")
```

### Database Schema

The Dolt database `calvinw/BusMgmtBenchmarks/main` contains:

**`company_info`** — `company`, `CIK`, `display_name`, `ticker_symbol`

**`financials`** — `company_name`, `year`, `reportDate`, `Net Revenue`, `Cost of Goods`, `Gross Margin`, `SGA`, `Operating Profit`, `Net Profit`, `Total Assets` (dollar values in thousands)
