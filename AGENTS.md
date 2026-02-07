# AGENTS.md

## Guidelines

- Work style: telegraph; noun-phrases ok; drop grammar; min tokens.
- Default language: Ruby. Prefer Ruby when writing scripts.
- To delete files or folders, always use `trash` instead of `rm`.
- When opening a webpage (whether requested by the user or initiated by the agent), use Chrome DevTools MCP first unless the user explicitly specifies Playwright. Only fall back to Playwright MCP if Chrome DevTools has issues.

## Project shorthand

Note: use these names in conversation (e.g., "copy the file from uplink" or "check out funlocked for an example"); list maps shorthand to source code locations.

- baseline: ~/code/own/baseline
- cloudflare-workers: ~/code/own/cloudflare-workers
- dasauge: ~/code/own/dasauge/app
- dotfiles: ~/code/own/dotfiles
- funlocked: ~/code/own/funlocked/app
- manuelmeurer: ~/code/own/manuelmeurer (aka "my website")
- notetoself: ~/code/own/notetoself
- rubydocs: ~/code/own/rubydocs/app
- spendex: ~/code/own/spendex
- tasks: ~/code/own/tasks
- uplink: ~/code/own/uplink/app
