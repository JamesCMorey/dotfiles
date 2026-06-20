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
