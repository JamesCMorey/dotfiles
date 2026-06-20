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
