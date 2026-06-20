# Secrets Registry

All credentials live in the **macOS login Keychain** (generic-password items).
This file lists item **names and purpose only — never values.**

To use a secret: reference it inline via
`$(security find-generic-password -s <item> -w)` in the command that needs it,
or call the matching script in `~/dotfiles/briefing/bin/`. Never echo, log, or
assign-and-print a secret. Helper: `source ~/dotfiles/briefing/lib/keychain.sh`
then `get_secret <item>`.

## Provisioned

| Keychain item (`-s`) | Used for | Access pattern |
|---|---|---|
| `dokploy-api-key` | Dokploy MCP server | env-ref via `claude()` launcher in `~/.zshrc.local` |
| `cf-user-token`   | Cloudflare R2 + account/billing API | inline / `bin/r2-usage` |

## Planned (P1)

- `b2-key-id`, `b2-app-key` — Backblaze B2 (inline / `bin/b2-usage`)
- payment/txn provider key — `bin/txn-summary` (provider TBD)

## Create an item (run yourself — Claude never sees the value)

```sh
security add-generic-password -s <item> -a "$USER" -w '<secret-value>' -T /usr/bin/security
```
