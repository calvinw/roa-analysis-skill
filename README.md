# dolt-db-tools

A GitHub Codespace for working with a Dolt database using AI coding tools.

## What's included

- All AI tools from [ai-course-devcontainer](https://github.com/calvinw/ai-course-devcontainer):
  Claude Code, OpenCode, Gemini CLI, Codex, Copilot, Crush, Pi agent
- All tools pre-configured with the Dolt MCP server

## MCP Server

All AI tools connect to the Dolt database via MCP (Model Context Protocol):

```
https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse
```

## Getting started

Open in GitHub Codespaces — all tools and MCP connections are set up automatically by `.devcontainer/post-create.sh`, including Codex via `codex mcp add`.
