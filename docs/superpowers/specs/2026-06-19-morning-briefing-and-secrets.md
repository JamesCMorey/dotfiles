# Morning Briefing + Secrets Manager — Design

**Date:** 2026-06-19
**Status:** Approved design, pre-implementation
**Home:** `~/dotfiles/briefing/` (stow-managed, git-tracked)

## 1. Context & Goals

A single, local, automated surface that (a) gives a morning digest of what matters and
(b) continuously watches cloud + payment accounts for "did I get hacked / is there a
surprise bill" anomalies — built with **just Claude Code + local config** (no hosted
service, no server to maintain).

This also fixes a concrete security problem observed on 2026-06-19: API keys were pasted
into chat and stored in plaintext (`~/.zshrc.local`). The secrets layer makes that
**structurally impossible** going forward.

### Goals
- Morning briefing delivered as a notification + a self-contained `dashboard.html` that
  can be reopened any time of day ("web UI" feel, zero server).
- Cost & security watchdog that runs around the clock and **pushes an alert only on
  anomaly**.
- All credentials stored encrypted in the **macOS login Keychain**; Claude/agents never
  receive raw secret values.
- Everything reproducible from `~/dotfiles` + two `launchd` jobs.

### Non-Goals
- No hosted/served web app, no time-series database, no interactive dashboard backend.
- No reliance on claude.ai-hosted MCP connectors (Gmail/Calendar/etc.) — they require
  interactive auth and are unavailable in a headless `claude -p` run. All data sources are
  locally reachable.
- Not a general secrets-management overhaul for other machines; this targets the user's
  primary Mac (local iTerm2 + tmux).

## 2. Architecture Overview

Three subsystems. The secrets layer is foundational; the briefing and watchdog are
consumers that share the same capability scripts.

```
~/dotfiles/briefing/
  bin/                        # capability scripts — the ONLY things that read secrets
    cal-today                 # today's events from macOS Calendar (EventKit)   [no secret]
    gmail-digest              # unread highlights via IMAP                       [Keychain]
    prod-health               # curl *.tackl.co + Dokploy status        [no secret/Keychain]
    r2-usage                  # Cloudflare R2 storage + MTD spend + tokens       [Keychain]
    b2-usage                  # Backblaze B2 storage + MTD spend + keys           [Keychain]
    txn-summary               # payment processor activity (provider TBD)        [Keychain]
    news-fetch                # RSS/headlines for chosen topics (TBD)            [no secret]
  lib/
    keychain.sh               # get_secret <item> helper (security ... -w)
    notify.sh                 # reuse existing ~/.claude notification hook plumbing
  generate-briefing           # orchestrator → claude -p → dashboard.html + .md + notify
  watchdog                    # threshold checks → escalate to claude only on anomaly
  templates/dashboard.html.tmpl
  state/                      # gitignored: baselines.json, last-run, *.log
  SECRETS.md                  # registry: Keychain item names + purpose (NO values)
~/Library/LaunchAgents/       # stow-symlinked
  co.tackl.briefing.plist     # StartCalendarInterval 07:00, runs on wake if missed
  co.tackl.watchdog.plist     # StartInterval ~3h, 24/7
~/briefings/
  dashboard.html              # stable path (bookmark this)
  YYYY-MM-DD.md               # dated archive
```

**Claude plays two roles:**
- **Generator (briefing):** deterministic pre-gather of all sources into one blob, then a
  single `claude -p` (headless Opus) call that *synthesizes* (prioritize the day, surface
  the few emails/news items that matter) and *renders* `dashboard.html`. Single
  deterministic call — not an agentic tool-call loop — for unattended reliability and cost.
- **Watchdog (cost/security):** mostly deterministic shell comparing metrics to baselines;
  **escalates to `claude -p` only when an anomaly trips**, for severity judgment + alert
  wording.

### Design Invariants
- Secrets live **only** in Keychain. Capability scripts in `bin/` are the sole readers.
  Claude sees results only.
- Pure local files + `launchd`. All scripts idempotent and safe to re-run.
- A failed source degrades its own section (`STATUS: unavailable`); it never fails the run.
- Delivery reuses the existing notification hook — no new notification mechanism.

## 3. Subsystem 1 — Secrets Manager (Keychain)

### Storage
macOS **login keychain**, one generic-password item per secret. Create with the `security`
binary trusted so unattended reads don't prompt:

```sh
security add-generic-password -s <item> -a jcm -w <secret> -T /usr/bin/security
```

The login keychain is auto-unlocked at GUI login and (by default) stays unlocked for the
session, so `launchd` agents running in the logged-in session read silently. (Caveat:
non-default "auto-lock on idle/sleep" would reintroduce a prompt; SSH sessions don't unlock
the GUI keychain — neither affects the local iTerm2/tmux + launchd use case.)

### Access patterns (two)
1. **Env-ref consumers** (e.g. Dokploy MCP via `.mcp.json`'s `${DOKPLOY_API_KEY}`):
   resolved **launcher-scoped**, not globally, so the value only enters Claude's process
   tree, only when launched:
   ```sh
   # ~/.zshrc.local
   claude() { DOKPLOY_API_KEY="$(security find-generic-password -s dokploy-api-key -w)" command claude "$@"; }
   ```
   Smaller blast radius than a global `export`; no per-shell lookup; silent (login keychain
   already unlocked + `security` trusted in the item ACL).
2. **Capability scripts / one-off agent commands** (`wrangler`, `b2`, `curl`, the `bin/`
   scripts): read Keychain **inline, scoped to a single command** — the value is substituted
   at exec time and never lands in the transcript:
   ```sh
   CF_API_TOKEN="$(security find-generic-password -s cf-user-token -w)" \
     curl -s -H "Authorization: Bearer $CF_API_TOKEN" https://api.cloudflare.com/...
   ```

### Migration of `~/.zshrc.local`
Every raw key currently in `~/.zshrc.local` is either:
- moved into Keychain and replaced by a **launcher-scoped lookup** (if an MCP/tool needs it
  in env), or
- removed entirely and fetched **inline** by whoever needs it.

After migration `~/.zshrc.local` contains no secret values.

### Agent discovery (how agents know creds moved to Keychain)
Three pieces:
1. **`~/dotfiles/briefing/SECRETS.md`** — a registry of Keychain item names + purpose +
   access pattern. **No values.** Example rows:

   | Keychain item (`-s`) | Used for | Access pattern |
   |---|---|---|
   | `dokploy-api-key` | Dokploy MCP server | env-ref via launcher |
   | `cf-user-token` | Cloudflare R2 + billing | inline / `bin/r2-usage` |
   | `b2-key-id`, `b2-app-key` | Backblaze B2 | inline / `bin/b2-usage` |

2. **Always-loaded instruction block** added to the workspace `AGENTS.md` *and* global
   `~/.claude/CLAUDE.md`:
   > All credentials live in the macOS login Keychain — see `~/dotfiles/briefing/SECRETS.md`.
   > Never ask the user to paste a secret and never print one. To use a secret, reference it
   > inline via `$(security find-generic-password -s <item> -w)` in the command that needs
   > it, or call the matching script in `~/dotfiles/briefing/bin/`. Never echo, log, or
   > assign-and-print a secret.
3. **`lib/keychain.sh`** exposing `get_secret <item>`, and `bin/*` capability scripts that
   wrap fetch→use→summarize so the easy path is the safe path.

## 4. Subsystem 2 — Briefing / Dashboard Generator

`generate-briefing`, triggered by `co.tackl.briefing.plist` (`StartCalendarInterval` 07:00,
runs on wake if the scheduled time was missed):

1. **Gather** — run `cal-today`, `prod-health`, `news-fetch`, and a cost snapshot from
   `r2-usage`/`b2-usage`/`txn-summary`; collect output (with each script's
   `STATUS: ok|unavailable`) into one context blob.
2. **Synthesize** — one `claude -p` (headless Opus) call with the blob + a synthesis+render
   prompt. Claude prioritizes the day, extracts the 2–3 emails/news items that matter, flags
   anything odd. (Pre-gather-then-synthesize, not agentic tool-calling, for unattended
   reliability/cost.)
3. **Render** — Claude writes self-contained `~/briefings/dashboard.html` (inline CSS;
   sections: Calendar · Inbox · News · Tackl status · Cloud cost · Alerts) plus dated
   markdown `~/briefings/YYYY-MM-DD.md`. Stable `dashboard.html` path is the reopen-anytime
   surface.
4. **Notify** — `notify.sh` fires "Morning briefing ready (N events · M alerts)"; click
   opens the HTML.

`--dry-run` writes to `/tmp` and skips the notification.

### Data sources & secret needs
- **Calendar** — local macOS Calendar via EventKit/`icalBuddy`; requires the Google account
  added to Apple Calendar; **no secret**.
- **Gmail highlights** — IMAP using an app password in Keychain.
- **Tackl prod health** — `curl` public `*.tackl.co` health endpoints (no secret) + optional
  Dokploy status (Keychain).
- **News** — RSS/`curl`, **no secret**; topics TBD.
- **Cloud cost snapshot** — shared with the watchdog (§5).

## 5. Subsystem 3 — Cost & Security Watchdog

`watchdog`, triggered by `co.tackl.watchdog.plist` (`StartInterval` ~every 3h, **24/7** so an
off-hours compromise isn't invisible until morning):

1. **Pull** metrics via the shared capability scripts: R2/B2 storage + MTD spend, today's txn
   count/amount, and **security signals** — set of API tokens/keys per account, bucket
   public/private flags, egress/request volume.
2. **Diff** against `state/baselines.json` (rolling typical spend, known key fingerprints,
   normal egress).
3. **Anomaly rules** — trip if any of:
   - **Spend ladder (per account, per calendar month):** alert when an account's
     month-to-date spend first becomes **non-zero**, then each time it crosses the next rung
     of a 1-2-5 ladder: **$5, $10, $20, $50, $100, $200, $500, $1,000, $2,000, $5,000, …**.
     Each rung fires **once** per account per month. `state/baselines.json` tracks the highest
     rung already alerted per account; it **resets when the billing month rolls over** (so the
     first dollar of the new month re-alerts). Multiple rungs crossed between runs → a single
     alert naming the highest rung reached.
   - a **new API key/token appeared** since last run
   - a bucket flipped **public**
   - **egress spike** >N× baseline (N tuned during implementation)
   - failed-payment surge
4. **On trip → escalate to `claude -p`** with just the diff; Claude judges severity and
   writes a tight alert; `notify.sh` pushes it; it also lands in the dashboard **Alerts**
   section.
5. **No trip → silent** (update `state/`, log only) to avoid alert fatigue.

### Security hardening
- Clean runs auto-update spend/egress baselines.
- A **newly-seen API key is NOT auto-trusted** — it stays flagged until the user
  acknowledges it, so a malicious key can't quietly baseline itself away.

`--check` prints what it would alert without notifying.

## 6. Scheduling & Delivery

- **`launchd` LaunchAgents** (run in the logged-in GUI session → keychain unlocked):
  - `co.tackl.briefing.plist`: `StartCalendarInterval` `{Hour:7,Minute:0}`. Native
    behavior: if asleep/off at 07:00, runs once on wake — satisfies "fire at a set time if
    the laptop's on, else soon after it opens."
  - `co.tackl.watchdog.plist`: `StartInterval` ~10800s (3h), 24/7.
  - `RunAtLoad` false; `StandardOutPath`/`StandardErrorPath` → `state/*.log`.
- **Delivery** reuses the existing `~/.claude/hooks/`-style notifier (`lib/notify.sh`
  wraps it). Briefing → AM notification; watchdog → anomaly notification.

## 7. Error Handling & Testing

- Capability scripts: `set -euo pipefail`, per-call timeouts, emit `STATUS: ok|unavailable`
  so consumers degrade one section gracefully.
- **Testable units:** capability scripts against API fixtures; watchdog threshold logic fed
  synthetic metrics → assert alert/no-alert (including the "new key not auto-trusted" rule).
  The `claude -p` synthesis step is smoke-tested via `--dry-run`.
- Dry-run/check modes (`generate-briefing --dry-run`, `watchdog --check`) for safe iteration.
- `state/` is gitignored.

## 8. Implementation Phasing

- **P0 — Secrets layer:** create Keychain items (`-T /usr/bin/security`); `lib/keychain.sh`;
  `SECRETS.md`; AGENTS.md + `~/.claude/CLAUDE.md` instruction block; migrate `~/.zshrc.local`
  to launcher-scoped lookups; remove plaintext keys. **Rotate the keys exposed on 2026-06-19
  as part of this.**
- **P1 — Capability scripts:** no-secret ones first (`cal-today`, `prod-health`,
  `news-fetch`), then `r2-usage`, `b2-usage`, `gmail-digest`, `txn-summary`.
- **P2 — Briefing:** `generate-briefing` + `templates/dashboard.html.tmpl` + `lib/notify.sh`
  + `co.tackl.briefing.plist`.
- **P3 — Watchdog:** `watchdog` + `state/baselines.json` + anomaly rules +
  `co.tackl.watchdog.plist`.

## 9. Open Items (TBD — do not block the spec)

- **Payment/transactions provider** for `txn-summary` (Stripe? VPS billing? other?).
- **News topics** for `news-fetch`.
- Egress-spike multiplier (N×) and failed-payment-surge thresholds — tuned against real
  baselines in P3. (Spend thresholds are **defined**: the 1-2-5 ladder in §5.)

## 10. Decisions Log

- **Delivery:** hybrid — scheduled generation of a self-contained `dashboard.html` + push
  notification, over a served web app (no server to maintain) or push-only markdown (wanted
  reopen-anytime surface).
- **Watchdog model:** push anomaly alerts over a pull-only dashboard (a dashboard only helps
  if you remember to look; an alert reaches you). Runs 24/7 for security coverage.
- **Secrets backend:** macOS Keychain over `pass`/1Password — native, zero-install, and
  login-unlocked so unattended `launchd` jobs read without a passphrase prompt.
- **Env-ref secret resolution:** launcher-scoped (`claude()` wrapper) over a global `export`
  — smaller blast radius, no per-shell lookup.
- **Briefing generation:** single pre-gather→synthesize `claude -p` call over agentic
  tool-calling — unattended reliability and cost.
- **Data sources:** local-only (EventKit calendar, IMAP gmail, `curl`/RSS) over claude.ai
  MCP connectors, which can't run headless.
- **Spend alerting:** per-account, per-month 1-2-5 rung ladder (first non-zero, then
  $5/$10/$20/$50/…), each rung once — predictable and tuning-free, over percentage/projection
  thresholds.
