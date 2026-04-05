---
name: ergo-portal
description: Download new PDF documents from the ERGO/DKV Kundenportal (meine.ergo.de). Use when checking for new ERGO/DKV documents, downloading Leistungsabrechnungen, or when an ERGO notification email arrives.
---

# ERGO Portal — PDF Download

Download new PDF documents from the ERGO/DKV Kundenportal for Karin Christa Meurer.

## Prerequisites

- **Browser**: Use the default OpenClaw browser profile/config for this installation (do not override profile/headless in the workflow). Chromium must be running with remote debugging (attachOnly setup).
- **1Password**: ERGO credentials in vault "Shared with Tom" (item "DKV / Ergo"). Load token from `~/.openclaw/.secrets/1password-sa.env`.
- **SMS Webhook**: OTP codes arrive in `memory/sms/YYYY-MM.json` (from field: `"ERGO"`).

## Workflow

### 1. Get credentials (1Password)

**Wichtig:** Credentials niemals in Chat/Logs ausgeben. Werte nur in Variablen halten und direkt zum Login verwenden.

```bash
# Load Service Account token (no output)
set -euo pipefail
OP_SERVICE_ACCOUNT_TOKEN="$(grep OP_SERVICE_ACCOUNT_TOKEN ~/.openclaw/.secrets/1password-sa.env | cut -d= -f2-)"
export OP_SERVICE_ACCOUNT_TOKEN

# Read fields into shell variables (do not echo)
ERGO_USERNAME="$(op item get "DKV / Ergo" --vault "Shared with Tom" --fields username)"
ERGO_PASSWORD="$(op item get "DKV / Ergo" --vault "Shared with Tom" --fields password)"
```

Then use `ERGO_USERNAME` / `ERGO_PASSWORD` to fill the login form via the browser tool.

### 2. Open login page

- Navigate to `https://kunde-s.ergo.de/meineversicherungen/lz/start.aspx?vu=ergo`
- Wait for the login form (look for textbox "Benutzername" / "Passwort")

### 3. Log in

- Click username field, type username
- Click password field, type password
- Click "Anmelden"
- Wait for dashboard ("Herzlich willkommen")

### 4. Navigate to Postfach

- Click "Postfach" link in the navigation
- Wait for message list to load

### 5. Identify new documents

**Only messages with a 📎 clip icon have PDF attachments.** In the accessibility tree, these show as `group "clip"` next to the message row.

Look for messages from the **last 2 days** that have a clip icon. These are the ones with downloadable PDFs.

**If multiple new documents exist**: Download only the most recent one. After sending it, inform the user that there are N more new documents with attachments from the last 2 days.

**If no new documents**: Inform the user that no new documents were found.

### 6. Open the message

- Click the message row (use `evaluate` with JS to click the table row matching the date and subject)
- Wait for message detail view (look for heading with the message subject)

### 7. Click the PDF link

- Find the link containing "(PDF)" in its text (e.g. "Leistungsabrechnung (PDF)")
- Click it
- This triggers the SMS-Kennwort flow

### 8. Request SMS-Kennwort

- On the OTP prompt page, click "SMS-Kennwort anfordern"
- Wait 5-10 seconds for the SMS to arrive

### 9. Read SMS code

Read the latest ERGO SMS from the webhook log:

```bash
jq -r '[.[] | select(.from=="ERGO")] | sort_by(.receivedAt // .timestamp) | last | .text' ~/. openclaw/workspace/memory/sms/$(date +%Y-%m).json
```

Extract the 6-digit code from the SMS text.

### 10. Enter SMS code and unlock

- Type the code into the "SMS-Kennwort" textbox
- Click "Freischalten"
- The PDF downloads automatically to `~/Downloads/`

### 11. Send PDF via Telegram

Downloads via the openclaw Chromium profile land in `/tmp/playwright-artifacts-*/` with UUID filenames (not `~/Downloads`).

```bash
# Find the latest downloaded file
find /tmp/playwright-artifacts-* -type f -mmin -5 | head -1
# Verify it's a PDF
file <path>
# Copy to allowed outbound path
cp <path> ~/.openclaw/media/outbound/<filename>.pdf
```

Then use `message` tool with `filePath` pointing to the outbound copy.

### 12. Logout

- Click "Logout" link (top-right navigation)
- Confirm the page returns to the login screen

## Important Notes

- **Bot detection**: ERGO tends to block headless/automated traffic. Use the default GUI (non-headless) browser setup configured for this OpenClaw install.
- **SMS timing**: After requesting the SMS-Kennwort, wait at least 5 seconds before checking the SMS log. If not found, retry after another 5 seconds (max 3 retries).
- **Session timeout**: ERGO sessions expire after ~15 minutes of inactivity. Complete the workflow promptly.
- **Message read state**: Both read and unread messages are relevant. Filter only by date and clip icon.
- **Driver quirks**: `slowly=true` may not be supported on this driver. Use regular `type` / `fill` / `press` for input.
