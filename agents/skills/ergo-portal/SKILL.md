---
name: ergo-portal
description: Download new PDF documents from the ERGO/DKV Kundenportal (meine.ergo.de). Use when checking for new ERGO/DKV documents, downloading Leistungsabrechnungen, or when an ERGO notification email arrives. Requires the user's Chromium browser running with remote debugging enabled (existing-session / "user" profile).
---

# ERGO Portal — PDF Download

Download new PDF documents from the ERGO/DKV Kundenportal for Karin Christa Meurer.

## Prerequisites

- **Browser**: Chromium must be running with remote debugging. Use `browser` tool with `profile="user"`.
- **1Password**: ERGO credentials in vault "Shared with Tom" (item "DKV / Ergo"). Load token from `~/.openclaw/.secrets/1password-sa.env`.
- **SMS Webhook**: OTP codes arrive in `memory/sms/YYYY-MM.json` (from field: `"ERGO"`).

## Workflow

### 1. Get credentials

```bash
export OP_SERVICE_ACCOUNT_TOKEN=$(grep OP_SERVICE_ACCOUNT_TOKEN ~/.openclaw/.secrets/1password-sa.env | cut -d= -f2-)
op item get "DKV / Ergo" --vault "Shared with Tom" --format json | jq '{username: (.fields[] | select(.id=="username") | .value), password: (.fields[] | select(.id=="password") | .value)}'
```

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

```bash
# Copy to allowed outbound path
cp ~/Downloads/<filename>.pdf ~/.openclaw/media/outbound/<filename>.pdf
```

Then use `message` tool with `filePath` pointing to the outbound copy.

### 12. Logout

- Click "Logout" link (top-right navigation)
- Confirm the page returns to the login screen

## Important Notes

- **Bot detection**: The headless openclaw browser (profile "openclaw") is blocked by ERGO's bot detection on `ciam.ergo.com`. Always use `profile="user"` (existing-session with real Chromium).
- **SMS timing**: After requesting the SMS-Kennwort, wait at least 5 seconds before checking the SMS log. If not found, retry after another 5 seconds (max 3 retries).
- **Session timeout**: ERGO sessions expire after ~15 minutes of inactivity. Complete the workflow promptly.
- **Message read state**: Both read and unread messages are relevant. Filter only by date and clip icon.
- **existing-session quirks**: `slowly=true` is not supported on this driver. Use regular `type` or `press` for input.
