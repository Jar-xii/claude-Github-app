# Universal Clock

A timezone converter that works as both a **website** and a **Discord bot**. One person enters a time (e.g. `8pm UK`) and everyone else sees it automatically converted to their personal timezone.

---

## Features

- Parse natural time input: `8pm UK`, `20:00 BST`, `3:30pm Eastern`, `1430 PST`, `noon UTC`, `midnight GMT`
- 150+ timezone aliases (city names, abbreviations, country names)
- Full IANA timezone passthrough (e.g. `Europe/London`, `America/New_York`)
- Shareable links — encode a time in a URL so anyone opening it sees it in their own timezone
- Discord bot with slash commands and autocomplete
- All timezone settings stored locally (website: localStorage, Discord: SQLite)

---

## Quick Start

```bash
cd clock
npm install
cp .env.example .env
# Edit .env with your Discord credentials (see Discord Setup below)
```

**Run the web server:**
```bash
npm run start:web
# Open http://localhost:3000
```

**Run the Discord bot:**
```bash
npm run start:bot
```

---

## Discord Setup

### 1. Create a Discord Application

1. Go to [discord.com/developers/applications](https://discord.com/developers/applications)
2. Click **New Application** → give it a name → **Create**

### 2. Get your Bot Token

1. In the left sidebar, click **Bot**
2. Click **Add Bot** → **Yes, do it!**
3. Under **Token**, click **Reset Token** → copy it
4. Paste it into `.env` as `DISCORD_TOKEN=...`

### 3. Get your Client ID

1. In the left sidebar, click **OAuth2 → General**
2. Copy the **Client ID**
3. Paste it into `.env` as `DISCORD_CLIENT_ID=...`

### 4. Invite the bot to your server

1. In the left sidebar, click **OAuth2 → URL Generator**
2. Under **Scopes**, check: `bot` and `applications.commands`
3. Under **Bot Permissions**, check: `Send Messages` and `Embed Links`
4. Copy the generated URL and open it in your browser to invite the bot

### 5. Register Slash Commands

For **instant** registration during development (recommended), set your server's ID in `.env`:
```bash
DISCORD_GUILD_ID=your_server_id_here
```
To find your server ID: right-click your server name in Discord → **Copy Server ID** (requires Developer Mode to be enabled in Discord settings).

Then run:
```bash
npm run deploy:commands
```

For **global** registration (takes up to 1 hour to propagate), leave `DISCORD_GUILD_ID` blank.

---

## Discord Bot Commands

### `/settz <timezone>`
Set your personal timezone. Supports aliases and IANA names. Has autocomplete.

```
/settz UK
/settz EST
/settz Tokyo
/settz Europe/London
/settz America/New_York
```

Your setting is stored in the SQLite database and persists across restarts.

### `/convert <time>`
Convert a time to everyone's local timezone. Posts a public embed visible to the whole server.

```
/convert 8pm UK
/convert 20:00 BST
/convert 3:30pm Eastern
/convert 1430 PST
/convert noon UTC
/convert midnight GMT
```

Shows a card with the original time and each registered user's local equivalent.

### `/listtz`
List all registered users and their current local times. Ephemeral (only you can see the reply).

---

## Website

Open `http://localhost:3000` after starting the web server.

### Pages

| URL | Purpose |
|---|---|
| `/` | Live clock in your timezone |
| `/settings` | Set your timezone (stored in localStorage) |
| `/converter` | Enter a time, see it in your timezone, get a shareable link |
| `/share?t=...&tz=...` | Open a shared time link |

### Sharing a time

1. Go to `/converter`
2. Type a time like `8pm UK`
3. Click **Copy link**
4. Anyone who opens that link sees the time converted to *their* timezone

The link encodes an ISO 8601 timestamp — it works forever and doesn't require the sender to be online.

---

## Timezone Aliases

You can use city names, abbreviations, or country names:

| Alias | Timezone |
|---|---|
| `UK`, `GB`, `BST` | `Europe/London` |
| `EST`, `ET`, `Eastern`, `NYC` | `America/New_York` |
| `PST`, `PT`, `Pacific`, `LA` | `America/Los_Angeles` |
| `CST`, `CT`, `Central`, `Chicago` | `America/Chicago` |
| `GMT`, `UTC` | `UTC` |
| `TOKYO`, `JST`, `Japan` | `Asia/Tokyo` |
| `SYDNEY`, `AEST`, `AEDT` | `Australia/Sydney` |
| `IST`, `India`, `Mumbai` | `Asia/Kolkata` |

Full IANA names also work: `Europe/Paris`, `America/Argentina/Buenos_Aires`, etc.

### Known Ambiguities

Some abbreviations are ambiguous. These are the defaults — use the explicit alternative to override:

| Alias | Default | Explicit alternative |
|---|---|---|
| `IST` | India (`Asia/Kolkata`) | `Europe/Dublin` (Ireland), `Asia/Jerusalem` (Israel) |
| `CST` | US Central (`America/Chicago`) | `CHINA` or `SHANGHAI` (China) |
| `AST` | Arabia (`Asia/Dubai`) | `HALIFAX` or `AST_ATLANTIC` (Atlantic) |

---

## Supported Input Formats

| Format | Example |
|---|---|
| `<H>pm <zone>` | `8pm UK` |
| `<HH>:<MM> <zone>` | `20:00 BST` |
| `<H>:<MM>pm <zone>` | `3:30pm Eastern` |
| `<H> pm <zone>` (space) | `3:30 pm EST` |
| Military `<HHMM> <zone>` | `1430 PST` |
| Named time | `noon UTC`, `midnight GMT` |
| IANA zone | `8pm Europe/London` |

---

## Running Tests

```bash
cd clock
npm test
```

Runs 61 tests across three suites:
- `timezoneAliases.test.js` — alias resolution
- `timeParser.test.js` — time parsing, 12am/pm edge cases, formats
- `api.test.js` — HTTP API endpoints

---

## Project Structure

```
clock/
├── shared/
│   ├── timezoneAliases.js   # Alias map + resolveAlias()
│   └── timeParser.js        # parseTimeInput(), convertTo(), formatForDisplay()
├── bot/
│   ├── database.js          # SQLite (shared with web server)
│   ├── deploy-commands.js   # Register slash commands with Discord
│   ├── index.js             # Discord bot entry point
│   └── commands/
│       ├── settz.js         # /settz
│       ├── convert.js       # /convert
│       └── listtz.js        # /listtz
├── web/
│   ├── server.js            # Express server
│   ├── routes/
│   │   ├── api.js           # /api/* endpoints
│   │   └── pages.js         # HTML page routes
│   └── public/              # Static frontend
│       ├── index.html       # Live clock
│       ├── settings.html    # Timezone picker
│       └── converter.html   # Time converter + share link
├── db/
│   └── schema.sql           # SQLite schema
├── tests/                   # Test suites
├── .env.example             # Environment variable template
└── package.json
```
