#!/usr/bin/env bash
# checks are passed as single-quoted strings and eval'd on purpose
# shellcheck disable=SC2016
# End-to-end tests against a throwaway HOME using the file backend and fake tokens.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CS="$ROOT/claude-switch"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

export HOME="$T" CLAUDE_SWITCH_BACKEND=file
unset CLAUDE_CONFIG_DIR
mkdir -p "$T/.claude"
CREDS="$T/.claude/.credentials.json"

fails=0
pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; fails=$((fails + 1)); }
# pipefail off inside checks: `grep -q` exits early and would SIGPIPE the writer
check() { if (set +o pipefail; eval "$2"); then pass "$1"; else fail "$1"; fi; }

# simulate `/login` as account $1 with access token $2
login() {
  printf '{"mcpOAuth":{"server":"MCP"},"claudeAiOauth":{"accessToken":"%s","refreshToken":"r-%s"}}' "$2" "$2" > "$CREDS"
  printf '{"theme":"dark","oauthAccount":{"accountUuid":"%s-uuid","emailAddress":"%s@example.com"}}' "$1" "$1" > "$T/.claude.json"
}
access_token() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["claudeAiOauth"]["accessToken"])' "$CREDS"; }

check "version flag" '"$CS" --version | grep -q "^claude-switch "'
check "list with no profiles" '"$CS" list 2>&1 | grep -q "no saved profiles"'
check "add refuses when logged out" '! "$CS" add x 2>/dev/null'

login work tokA
check "add first account" '"$CS" add work 2>/dev/null'
check "add rejects duplicate account" '! "$CS" add other 2>/dev/null'
check "add rejects bad name" '! "$CS" add "../x" 2>/dev/null'

login personal tokB
check "add second account" '"$CS" add personal 2>/dev/null'
check "list marks active" '"$CS" list | grep -q "^\* personal"'

"$CS" use work 2>/dev/null
check "use swaps token" '[[ "$(access_token)" == tokA ]]'
check "use swaps identity" '"$CS" current | grep -q "^work "'
check "use keeps MCP tokens" 'grep -q "\"MCP\"" "$CREDS"'
check "use keeps other config" 'grep -q "\"theme\": \"dark\"" "$T/.claude.json"'
check "use on active is a no-op" '"$CS" use work 2>&1 | grep -q "already using"'

# Claude Code rotates tokens while in use; switching away must keep the new one
python3 - "$CREDS" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); d["claudeAiOauth"]["accessToken"] = "tokA2"
json.dump(d, open(sys.argv[1], "w"))
PY
"$CS" next 2>/dev/null
check "next rotates" '"$CS" current | grep -q "^personal "'
"$CS" work 2>/dev/null
check "rotated token survives round trip" '[[ "$(access_token)" == tokA2 ]]'

check "unknown profile errors" '! "$CS" use nope 2>/dev/null'
check "refuses custom config dir" '! CLAUDE_CONFIG_DIR=/tmp/x "$CS" list 2>/dev/null'
check "remove profile" '"$CS" remove personal 2>/dev/null && ! "$CS" list | grep -q personal'
check "remove leaves login alone" '[[ "$(access_token)" == tokA2 ]]'
check "store is private" '[[ "$(stat -c %a "$T/.claude-switch" 2>/dev/null || stat -f %Lp "$T/.claude-switch")" == 700 ]]'

echo
if (( fails )); then echo "$fails test(s) failed"; exit 1; fi
echo "all tests passed"
