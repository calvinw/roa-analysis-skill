# ai-codespace-skill-and-mcp

A GitHub Codespace template that wires up a remote MCP server and a custom skill across every major AI coding tool — Claude Code, OpenCode, Gemini CLI, Codex, Copilot, and Crush.

## What this does

When you open this Codespace, all AI tools are automatically configured to connect to a shared MCP (Model Context Protocol) server. A single skill is pre-loaded that any tool can run with a slash command.

This is a minimal, working example of the pattern. Swap in your own MCP URL and write your own skill to build on top of it.

## AI Tools

All tools are pre-installed and pre-configured:
Claude Code, OpenCode, Gemini CLI, Codex, Copilot, Crush
(from [ai-course-devcontainer](https://github.com/calvinw/ai-course-devcontainer))

## MCP Server

| Server | Purpose |
|--------|---------|
| **dolt** | Read/write the BusMgmtBenchmarks Dolt database |

Endpoint: `https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse`

To add or change MCP servers, edit `configs/mcp-urls.conf` — all tools pick it up automatically on next boot.

## Skill

| Command | What it does |
|---------|-------------|
| `/roa-analysis TICKER1 TICKER2 YEAR` | Compare two companies side by side using the ROA DuPont breakdown |

Example: `/roa-analysis WMT M 2024`

The skill queries the Dolt database for both companies, calculates Net Profit Margin % × Asset Turnover = ROA, and displays a side-by-side table with plain-English interpretation.

## Getting started

Open in GitHub Codespaces — all tools and MCP connections are set up automatically by `.devcontainer/post-create.sh`.

## Customizing

- **Add an MCP server:** Add a line to `configs/mcp-urls.conf` in `name=url` format
- **Add a skill:** Create a folder under `.skillshare/skills/` with a `SKILL.md` file

## Documentation

- [AGENTS.md](AGENTS.md) — Technical reference: how MCP setup works, file layout, how to add MCPs and skills
- [CLAUDE.md](CLAUDE.md) — Claude Code behavior rules and skill usage guide
