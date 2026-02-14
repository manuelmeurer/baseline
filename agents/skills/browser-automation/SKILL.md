---
name: browser-automation
description: Automate browser interactions for web testing, form filling, screenshots, and data extraction. Use when the user needs to navigate websites, interact with web pages, fill forms, take screenshots, test web applications, or extract information from web pages.
---

# Browser Automation

## Tools

Two tools are available for browser automation:

1. **playwright-cli** — CLI tool for scripted browser automation. Preferred for most tasks.
2. **Chrome DevTools MCP** — MCP server for direct browser control via DevTools protocol.

**Default to playwright-cli.** Only use Chrome DevTools MCP if:
- playwright-cli is not available
- The task requires interacting with an already-open browser session
- The task specifically needs DevTools features (e.g. network inspection, performance tracing)

## playwright-cli

For detailed instructions, read the upstream skill file:
https://raw.githubusercontent.com/microsoft/playwright-cli/refs/heads/main/skills/playwright-cli/SKILL.md
and the reference documents it mentions for specific tasks.

## Chrome DevTools MCP

For detailed instructions, read the tool reference:
https://raw.githubusercontent.com/ChromeDevTools/chrome-devtools-mcp/refs/heads/main/docs/tool-reference.md
