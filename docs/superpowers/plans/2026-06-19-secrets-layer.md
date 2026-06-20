# Secrets Layer (P0) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all credentials into the macOS login Keychain and give agents a safe, discoverable way to use them — so secrets never land in a chat transcript or a plaintext file again.

**Architecture:** A sourced bash helper (`lib/keychain.sh`) wraps `security find-generic-password`. A registry (`SECRETS.md`) plus always-loaded instruction blocks in `AGENTS.md`/`CLAUDE.md` tell agents where secrets are and how to use them without revealing values. Env-ref secrets (the Dokploy MCP key) are resolved launcher-scoped in `~/.zshrc.local`; everything else is read inline by capability scripts. Exposed keys are rotated as part of provisioning.

**Tech Stack:** bash, macOS `security` (Keychain), `bats-core` (tests), zsh (launcher wrapper), git.

## Global Constraints

- **Platform:** macOS only (login keychain + launchd). Targets the user's primary Mac.
- **Secrets stored ONLY in the macOS login Keychain.** Claude/agents never receive raw secret values; capability scripts in `~/dotfiles/briefing/bin/` are the sole readers.
- **Create every Keychain item with `-T /usr/bin/security`** so unattended `launchd` reads don't prompt.
- **All shell scripts begin with `set -euo pipefail`** (except sourced libraries, which must not set `-e`).
- **Home:** everything under `~/dotfiles/briefing/`; `state/` and `*.log` are gitignored.
- **Secret VALUES are entered by the user only.** Any step that handles a raw secret is marked **USER ACTION**; Claude must not read, echo, or store the value.
- **Commits** are scoped to the task and end with:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`

---

### Task 1: `get_secret` helper + test harness

**Files:**
- Create: `~/dotfiles/briefing/lib/keychain.sh`
- Test: `~/dotfiles/briefing/tests/keychain.bats`
- Create: `~/dotfiles/briefing/.gitignore`
- Modify: `~/dotfiles/Brewfile` (add `bats-core`)

**Interfaces:**
- Produces: `get_secret <item>` → prints the Keychain value on stdout, returns `security`'s exit code (non-zero + empty stdout if absent), returns `2` if no item name given. `require_secret <item>` → prints value or fails (exit 1) with guidance to `SECRETS.md`. Both are consumed by every P1 capability script and the `~/.zshrc.local` launcher.

- [ ] **Step 1: Add the test tool to the Brewfile and install it**

Append to `~/dotfiles/Brewfile`:
```ruby
brew "bats-core"
```
Run:
```bash
brew install bats-core
bats --version
```
Expected: prints e.g. `Bats 1.x.y`.

- [ ] **Step 2: Create the package scaffolding**

```bash
mkdir -p ~/dotfiles/briefing/lib ~/dotfiles/briefing/tests
printf 'state/\n*.log\n' > ~/dotfiles/briefing/.gitignore
```

- [ ] **Step 3: Write the failing test**

Create `~/dotfiles/briefing/tests/keychain.bats`:
```bash
#!/usr/bin/env bats
# Tests for lib/keychain.sh against the real macOS login keychain.

setup() {
  source "${BATS_TEST_DIRNAME}/../lib/keychain.sh"
  TEST_ITEM="briefing-test-${BATS_TEST_NUMBER}-$$"
  security add-generic-password -s "$TEST_ITEM" -a "$USER" -w "s3cr3t-value" -T /usr/bin/security
}

teardown() {
  security delete-generic-password -s "$TEST_ITEM" >/dev/null 2>&1 || true
}

@test "get_secret returns the stored value" {
  run get_secret "$TEST_ITEM"
  [ "$status" -eq 0 ]
  [ "$output" = "s3cr3t-value" ]
}

@test "get_secret on a missing item is non-zero with empty output" {
  run get_secret "briefing-absent-$$"
  [ "$status" -ne 0 ]
  [ -z "$output" ]
}

@test "get_secret with no argument returns code 2" {
  run get_secret
  [ "$status" -eq 2 ]
}

@test "require_secret returns the value when present" {
  run require_secret "$TEST_ITEM"
  [ "$status" -eq 0 ]
  [ "$output" = "s3cr3t-value" ]
}

@test "require_secret fails with guidance when missing" {
  run require_secret "briefing-absent-$$"
  [ "$status" -eq 1 ]
  [[ "$output" == *"not in Keychain"* ]]
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `bats ~/dotfiles/briefing/tests/keychain.bats`
Expected: FAIL — `get_secret: command not found` (the lib doesn't exist yet).

- [ ] **Step 5: Write the minimal implementation**

Create `~/dotfiles/briefing/lib/keychain.sh`:
```bash
#!/usr/bin/env bash
# keychain.sh — read secrets from the macOS login Keychain.
# Source this file, then call get_secret / require_secret.
# NEVER echo, log, or assign-and-print the returned value (see SECRETS.md).
# (Sourced library: do NOT set -e/-u here — it would leak into the caller's shell.)

# get_secret <item>: print the secret for generic-password item <item>.
# Returns security's exit code (non-zero, empty stdout) if the item is absent.
get_secret() {
  local item="$1"
  if [ -z "$item" ]; then
    echo "get_secret: missing Keychain item name" >&2
    return 2
  fi
  security find-generic-password -s "$item" -w 2>/dev/null
}

# require_secret <item>: like get_secret but fails loudly if missing/empty.
require_secret() {
  local item="$1" val
  val="$(get_secret "$item")" || true
  if [ -z "$val" ]; then
    echo "require_secret: '$item' not in Keychain — see ~/dotfiles/briefing/SECRETS.md" >&2
    return 1
  fi
  printf '%s' "$val"
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `bats ~/dotfiles/briefing/tests/keychain.bats`
Expected: PASS — `5 tests, 0 failures`.

- [ ] **Step 7: Commit**

```bash
cd ~/dotfiles
git add briefing/lib/keychain.sh briefing/tests/keychain.bats briefing/.gitignore Brewfile
git commit -m "feat(briefing): add Keychain get_secret helper + bats harness

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Secrets registry + agent-discovery instructions

**Files:**
- Create: `~/dotfiles/briefing/SECRETS.md`
- Test: `~/dotfiles/briefing/tests/docs.bats`
- Modify: `~/code/tackl/AGENTS.md` (append a `## Secrets` section)
- Create: `~/.claude/CLAUDE.md` (global instruction file)

**Interfaces:**
- Consumes: `get_secret` (Task 1), referenced from the instruction text.
- Produces: the always-loaded convention every future agent reads — the string `macOS login Keychain` appears in both `AGENTS.md` and `CLAUDE.md`, and `SECRETS.md` lists item names `dokploy-api-key` and `cf-user-token`.

- [ ] **Step 1: Write the failing test**

Create `~/dotfiles/briefing/tests/docs.bats`:
```bash
#!/usr/bin/env bats
# Verifies the secrets registry and the always-loaded agent instructions exist.

@test "SECRETS.md registers the core Keychain items" {
  grep -q "dokploy-api-key" "$HOME/dotfiles/briefing/SECRETS.md"
  grep -q "cf-user-token" "$HOME/dotfiles/briefing/SECRETS.md"
}

@test "workspace AGENTS.md instructs Keychain usage" {
  grep -q "macOS login Keychain" "$HOME/code/tackl/AGENTS.md"
}

@test "global CLAUDE.md instructs Keychain usage" {
  grep -q "macOS login Keychain" "$HOME/.claude/CLAUDE.md"
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `bats ~/dotfiles/briefing/tests/docs.bats`
Expected: FAIL — `SECRETS.md` / `CLAUDE.md` don't exist; `AGENTS.md` lacks the string.

- [ ] **Step 3: Create the registry**

Create `~/dotfiles/briefing/SECRETS.md`:
```markdown
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
```

- [ ] **Step 4: Append the instruction block to the workspace AGENTS.md**

Append to `~/code/tackl/AGENTS.md`:
```markdown

## Secrets

All credentials live in the **macOS login Keychain** — see `~/dotfiles/briefing/SECRETS.md`
for the item registry. Never ask the user to paste a secret, and never print one. To use a
secret, reference it inline via `$(security find-generic-password -s <item> -w)` in the
command that needs it, or call the matching capability script in `~/dotfiles/briefing/bin/`.
Never echo, log, or assign-and-print a secret. The Dokploy MCP key is injected into Claude's
environment by the `claude()` launcher in `~/.zshrc.local` — do not hardcode it.
```

- [ ] **Step 5: Create the global CLAUDE.md**

Create `~/.claude/CLAUDE.md`:
```markdown
# Global instructions

## Secrets

All credentials live in the **macOS login Keychain** — see
`~/dotfiles/briefing/SECRETS.md` for the registry. Never ask me to paste a secret, and
never print one. To use a secret, reference it inline via
`$(security find-generic-password -s <item> -w)` in the command that needs it, or call the
matching script in `~/dotfiles/briefing/bin/`. Never echo, log, or assign-and-print a secret.
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `bats ~/dotfiles/briefing/tests/docs.bats`
Expected: PASS — `3 tests, 0 failures`.

- [ ] **Step 7: Commit (two repos)**

```bash
cd ~/dotfiles
git add briefing/SECRETS.md briefing/tests/docs.bats
git commit -m "docs(briefing): add secrets registry + agent-discovery test

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"

cd ~/code/tackl
git add AGENTS.md
git commit -m "docs: point agents at Keychain-backed secrets (SECRETS.md)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```
(`~/.claude/CLAUDE.md` is a global file, not in a tracked repo — no commit.)

---

### Task 3: Provision Keychain, rotate keys, migrate `~/.zshrc.local`

This task handles real secret material. Steps marked **USER ACTION** are run by the user; Claude must not read or echo any value. Claude performs only the verification steps (which never print a secret).

**Files:**
- Modify: `~/.zshrc.local` (remove raw `export` secret lines; add launcher wrapper) — untracked, machine-local.

**Interfaces:**
- Consumes: `dokploy-api-key`, `cf-user-token` Keychain items; `get_secret` (Task 1).
- Produces: a `claude()` shell function exporting `DOKPLOY_API_KEY` launcher-scoped; the Dokploy MCP (`.mcp.json` `${DOKPLOY_API_KEY}`) keeps working.

- [ ] **Step 1: List which secrets to migrate (names only — safe)**

Run:
```bash
grep -oE 'export [A-Z_]+' ~/.zshrc.local
```
Expected: `export DOKPLOY_API_KEY` and `export CF_USER_TOKEN`. These two are migrated below.

- [ ] **Step 2: USER ACTION — rotate the exposed keys**

These two keys were pasted into chat transcripts on 2026-06-19, so rotate before storing:
- **Dokploy:** dashboard → API/tokens → revoke the current key, generate a new one.
- **Cloudflare:** dashboard → My Profile → API Tokens → roll the token used for R2/account access.

Keep each **new** value on your clipboard for the next step. Do not paste it into chat.

- [ ] **Step 3: USER ACTION — store the new values in the Keychain**

Run each yourself, pasting the new value in place of `<paste-...>` (history-safe: prefix with a space if your shell ignores space-prefixed history, or use `-w` with a prompt):
```sh
security add-generic-password -s dokploy-api-key -a "$USER" -w '<paste-new-dokploy-key>' -T /usr/bin/security
security add-generic-password -s cf-user-token  -a "$USER" -w '<paste-new-cf-token>'    -T /usr/bin/security
```

- [ ] **Step 4: Verify the items are readable (no value printed)**

Run:
```bash
security find-generic-password -s dokploy-api-key -w >/dev/null 2>&1 && echo "dokploy-api-key: stored"
security find-generic-password -s cf-user-token  -w >/dev/null 2>&1 && echo "cf-user-token: stored"
```
Expected: both print `…: stored`. (Redirecting to `/dev/null` confirms presence without revealing the secret.)

- [ ] **Step 5: USER ACTION — replace `~/.zshrc.local` with the no-secret version**

Open `~/.zshrc.local` and replace the two raw `export DOKPLOY_API_KEY=…` / `export CF_USER_TOKEN=…` lines so the file reads (keep any other unrelated local config you already have):
```sh
# ~/.zshrc.local — machine-local shell config (NOT in git). No secret VALUES here.
# Secrets live in the macOS login Keychain (see ~/dotfiles/briefing/SECRETS.md).

# Launcher-scoped secret resolution: only Claude's process tree gets DOKPLOY_API_KEY,
# and only when launched. Silent read (login keychain already unlocked).
claude() {
  DOKPLOY_API_KEY="$(security find-generic-password -s dokploy-api-key -w 2>/dev/null)" \
    command claude "$@"
}
```
`CF_USER_TOKEN` is intentionally **not** re-exported — capability scripts read `cf-user-token` inline from the Keychain.

- [ ] **Step 6: Verify no literal secret remains and the launcher is active**

Run:
```bash
grep -nE '=[A-Za-z0-9._-]{20,}' ~/.zshrc.local || echo "clean: no literal secrets in ~/.zshrc.local"
exec zsh
type claude
```
Expected: `clean: no literal secrets…`, then after the new shell, `claude is a shell function`.

- [ ] **Step 7: Verify the Dokploy MCP still authenticates end-to-end**

Run:
```bash
cd ~/code/tackl && claude
```
In the session, confirm the `dokploy-mcp` server loads its tools (e.g. ask it to list projects / confirm the "Tacklbox" project resolves). The key now comes from the Keychain via the launcher, not a plaintext file.

- [ ] **Step 8: Confirm the full P0 suite is green**

Run: `bats ~/dotfiles/briefing/tests/`
Expected: PASS — all keychain + docs tests pass. No commit needed (`~/.zshrc.local` is untracked).

---

## Self-Review

**Spec coverage (§3 of the spec):**
- Keychain storage with `-T /usr/bin/security` → Task 1 (helper), Task 3 (provisioning). ✓
- Launcher-scoped env-ref resolution → Task 3, Step 5. ✓
- Inline access pattern → documented in `SECRETS.md`/`AGENTS.md`/`CLAUDE.md` (Task 2); exercised by P1 scripts. ✓
- `~/.zshrc.local` migration (no secret values) → Task 3. ✓
- Agent discovery (registry + AGENTS.md + CLAUDE.md + `get_secret`) → Tasks 1–2. ✓
- Rotate keys exposed 2026-06-19 → Task 3, Step 2. ✓
- macOS ACL no-prompt gotcha → Global Constraints + every `add-generic-password` uses `-T /usr/bin/security`. ✓

**Placeholder scan:** The only `<paste-…>` tokens are raw secret values that, by design, must be user-supplied — Claude must never hold them. No other placeholders.

**Type consistency:** `get_secret`/`require_secret` names and contract match across Task 1 (definition), Task 2 (docs reference), Task 3 (usage). Keychain item names `dokploy-api-key` / `cf-user-token` are identical in `SECRETS.md`, the launcher, and all verification commands.

**Out of scope (later plans):** capability scripts `bin/*` (P1), briefing generator + dashboard + launchd (P2), watchdog + spend ladder + launchd (P3). `b2-*` and txn items are registered as "Planned" only.
