# Codex MCP Notes

## Problem

The MCP servers in [`.claude/settings.json`](/workspaces/bus-mgmt-benchmarks-dolt-db/.claude/settings.json) use legacy SSE endpoints:

- `https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse`
- `https://bus-mgmt-databases.mcp.mathplosion.com/mcp-sec-10ks/sse`
- `https://bus-mgmt-databases.mcp.mathplosion.com/mcp-yfinance-10ks/sse`

Claude can register these directly with `claude mcp add --transport sse`.

Current Codex CLI (`codex-cli 0.117.0`) cannot. Its `codex mcp add --url ...` path expects streamable HTTP, not legacy SSE. Registering the `/sse` URLs directly causes MCP startup failures like:

`UnexpectedContentType(Some("text/plain; charset=utf-8; body: Method Not Allowed"))`

## Fix

Codex should register these servers through a pinned local `supergateway`
install as stdio MCP servers.

Using `npx -y supergateway ...` can fail if the transient npm cache contains an
incomplete install. A workspace-local install avoids that failure mode.

The working command shape is:

```bash
/workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse URL --logLevel none
```

## post-create.sh Change

[`scripts/setup-codex.sh`](/workspaces/bus-mgmt-benchmarks-dolt-db/scripts/setup-codex.sh) now:

```bash
mkdir -p "$WORKSPACE_DIR/.codex-tools/supergateway"
npm install --prefix "$WORKSPACE_DIR/.codex-tools/supergateway"
codex mcp add "$name" -- "$WORKSPACE_DIR/.codex-tools/supergateway/node_modules/.bin/supergateway" --sse "$url" --logLevel none
```

instead of:

```bash
codex mcp add "$name" -- npx -y supergateway --sse "$url" --logLevel none
```

## Expected Result

After setup, `codex mcp list` should show local command-based entries for all
three MCPs:

- `dolt`
- `mcp-sec-10ks`
- `mcp-yfinance-10ks`

Example:

```text
dolt               /workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse --logLevel none
mcp-sec-10ks       /workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse https://bus-mgmt-databases.mcp.mathplosion.com/mcp-sec-10ks/sse --logLevel none
mcp-yfinance-10ks  /workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse https://bus-mgmt-databases.mcp.mathplosion.com/mcp-yfinance-10ks/sse --logLevel none
```

## After Reboot

Run:

```bash
bash .devcontainer/post-create.sh
codex mcp list
```

If the list still shows `npx -y supergateway ...`, the older transient install
path is still present somewhere.

If needed, remove and re-add them manually:

```bash
codex mcp remove dolt
codex mcp remove mcp-sec-10ks
codex mcp remove mcp-yfinance-10ks

codex mcp add dolt -- /workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse https://bus-mgmt-databases.mcp.mathplosion.com/mcp-dolt-database/sse --logLevel none
codex mcp add mcp-sec-10ks -- /workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse https://bus-mgmt-databases.mcp.mathplosion.com/mcp-sec-10ks/sse --logLevel none
codex mcp add mcp-yfinance-10ks -- /workspaces/bus-mgmt-benchmarks-dolt-db/.codex-tools/supergateway/node_modules/.bin/supergateway --sse https://bus-mgmt-databases.mcp.mathplosion.com/mcp-yfinance-10ks/sse --logLevel none
```
