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
