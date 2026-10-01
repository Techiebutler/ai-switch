#!/usr/bin/env bash
# checks are passed as single-quoted strings and eval'd on purpose
# shellcheck disable=SC2016,SC2034
# End-to-end tests against a throwaway HOME using the file backend and fake tokens.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
AS="$ROOT/ai-switch"
CS="$ROOT/claude-switch"
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

export HOME="$T" AI_SWITCH_BACKEND=file AI_SWITCH_SKIP_PROCESS_CHECK=1
unset CLAUDE_CONFIG_DIR CODEX_HOME AI_SWITCH_HOME CLAUDE_SWITCH_HOME
mkdir -p "$T/.claude" "$T/.codex"
CREDS="$T/.claude/.credentials.json"
if [[ "$(uname)" == Darwin ]]; then
  CURSOR_DB="$T/Library/Application Support/Cursor/User/globalStorage/state.vscdb"
else
  CURSOR_DB="$T/.config/Cursor/User/globalStorage/state.vscdb"
fi

fails=0
pass() { echo "ok   - $1"; }
fail() { echo "FAIL - $1"; fails=$((fails + 1)); }
# pipefail off inside checks: `grep -q` exits early and would SIGPIPE the writer
check() { if (set +o pipefail; eval "$2"); then pass "$1"; else fail "$1"; fi; }

jwt() { # fake unsigned JWT with the given JSON payload
  local p
  p="$(printf '%s' "$1" | base64 | tr -d '=\n' | tr '/+' '_-')"
  printf 'eyJhbGciOiJub25lIn0.%s.sig' "$p"
}

# simulate logging in to each tool as account $1 with token $2
claude_login() {
  printf '{"mcpOAuth":{"server":"MCP"},"claudeAiOauth":{"accessToken":"%s","refreshToken":"r-%s"}}' "$2" "$2" > "$CREDS"
  printf '{"theme":"dark","oauthAccount":{"accountUuid":"%s-uuid","emailAddress":"%s@example.com"}}' "$1" "$1" > "$T/.claude.json"
}
codex_login() {
  local id
  id="$(jwt "{\"sub\":\"$1-sub\",\"email\":\"$1@example.com\",\"https://api.openai.com/auth\":{\"chatgpt_plan_type\":\"plus\"}}")"
  printf '{"auth_mode":"chatgpt","OPENAI_API_KEY":null,"tokens":{"id_token":"%s","access_token":"%s","refresh_token":"r","account_id":"%s-acct"}}' "$id" "$2" "$1" > "$T/.codex/auth.json"
  chmod 600 "$T/.codex/auth.json"
}
cursor_login() {
  python3 - "$CURSOR_DB" "$1" "$2" "$(jwt "{\"sub\":\"$1-sub\"}")" <<'PY'
import os, sqlite3, sys
db, who, tok, jwt = sys.argv[1:]
os.makedirs(os.path.dirname(db), exist_ok=True)
con = sqlite3.connect(db)
con.execute("CREATE TABLE IF NOT EXISTS ItemTable (key TEXT UNIQUE ON CONFLICT REPLACE, value BLOB)")
con.execute("INSERT INTO ItemTable VALUES ('workbench.theme', 'dark')")
con.execute("DELETE FROM ItemTable WHERE key LIKE 'cursorAuth/%'")
con.executemany("INSERT INTO ItemTable VALUES (?, ?)", [
    ("cursorAuth/accessToken", jwt + tok), ("cursorAuth/refreshToken", "r-" + tok),
    ("cursorAuth/cachedEmail", who + "@example.com")])
con.commit()
PY
}
claude_token() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["claudeAiOauth"]["accessToken"])' "$CREDS"; }
codex_token() { python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["tokens"]["access_token"])' "$T/.codex/auth.json"; }
cursor_value() { python3 -c 'import sqlite3,sys; print(sqlite3.connect(sys.argv[1]).execute("select value from ItemTable where key=?",(sys.argv[2],)).fetchone()[0])' "$CURSOR_DB" "$1"; }
mode_of() { stat -c %a "$1" 2>/dev/null || stat -f %Lp "$1"; }

echo "# general"
check "version flag" '"$AS" --version | grep -q "^ai-switch 2"'
check "list with nothing saved" '"$AS" list 2>&1 | grep -q "no saved profiles"'
check "add needs a tool" '! "$AS" add x 2>/dev/null'
check "add refuses when logged out" '! "$AS" claude add x 2>/dev/null'
check "reserved names rejected" '! "$AS" claude add codex 2>/dev/null'

echo "# migration from claude-switch 1.x"
mkdir -p "$T/.claude-switch/old"
printf '{"accountUuid":"old-uuid","emailAddress":"old@example.com"}' > "$T/.claude-switch/old/account.json"
printf '{"accessToken":"tokOld","refreshToken":"r"}' > "$T/.claude-switch/old/credentials.json"
check "legacy profile is migrated" '"$AS" claude list | grep -q "old  *old@example.com"'
check "legacy store is removed" '[[ ! -e "$T/.claude-switch" ]]'
"$AS" claude remove old 2>/dev/null

echo "# claude"
claude_login work tokA
check "add first account" '"$AS" claude add work 2>/dev/null'
check "add rejects duplicate account" '! "$AS" claude add other 2>/dev/null'
check "add rejects bad name" '! "$AS" claude add "../x" 2>/dev/null'
claude_login personal tokB
check "add second account" '"$AS" claude add personal 2>/dev/null'
check "list marks active" '"$AS" claude list | grep -q "^\* personal"'
"$AS" claude work 2>/dev/null
check "switch swaps token" '[[ "$(claude_token)" == tokA ]]'
check "switch swaps identity" '"$AS" claude current | grep -q "^work "'
check "switch keeps MCP tokens" 'grep -q "\"MCP\"" "$CREDS"'
check "switch keeps other config" 'grep -q "\"theme\": \"dark\"" "$T/.claude.json"'
check "switch to active is a no-op" '"$AS" claude use work 2>&1 | grep -q "already using"'
python3 - "$CREDS" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); d["claudeAiOauth"]["accessToken"] = "tokA2"
json.dump(d, open(sys.argv[1], "w"))
PY
"$AS" claude next 2>/dev/null
check "next rotates" '"$AS" claude current | grep -q "^personal "'
"$AS" claude work 2>/dev/null
check "rotated token survives round trip" '[[ "$(claude_token)" == tokA2 ]]'
check "unknown profile errors" '! "$AS" claude use nope 2>/dev/null'
check "refuses custom config dir" '! CLAUDE_CONFIG_DIR=/tmp/x "$AS" claude list 2>/dev/null'

echo "# claude-switch shortcut"
check "shortcut lists claude" '"$CS" list | grep -q "^\* work"'
check "shortcut switches" '"$CS" personal 2>/dev/null && [[ "$(claude_token)" == tokB ]]'
check "shortcut version" '"$CS" --version | grep -q "^claude-switch "'

echo "# codex"
codex_login work cA
check "codex add" '"$AS" codex add work 2>/dev/null'
codex_login personal cB
check "codex add second" '"$AS" codex add personal 2>/dev/null'
check "codex shows plan" '"$AS" codex list | grep -q "personal@example.com (plus)"'
"$AS" codex work 2>/dev/null
check "codex switch" '[[ "$(codex_token)" == cA ]]'
check "codex auth stays private" '[[ "$(mode_of "$T/.codex/auth.json")" == 600 ]]'
printf '[x]\ncli_auth_credentials_store = "keyring"\n' > "$T/.codex/config.toml"
check "codex refuses keyring store" '! "$AS" codex list 2>/dev/null'
rm "$T/.codex/config.toml"

echo "# cursor"
cursor_login work kA
check "cursor add" '"$AS" cursor add work 2>/dev/null'
cursor_login personal kB
check "cursor add second" '"$AS" cursor add personal 2>/dev/null'
"$AS" cursor work 2>/dev/null
check "cursor switch" '[[ "$(cursor_value cursorAuth/cachedEmail)" == work@example.com ]]'
check "cursor keeps other settings" '[[ "$(cursor_value workbench.theme)" == dark ]]'

echo "# all tools"
check "switch everything named personal" '"$AS" personal 2>/dev/null'
check "claude followed" '[[ "$(claude_token)" == tokB ]]'
check "codex followed" '[[ "$(codex_token)" == cB ]]'
check "cursor followed" '[[ "$(cursor_value cursorAuth/cachedEmail)" == personal@example.com ]]'
check "current shows every tool" '[[ "$("$AS" current | grep -c personal)" == 3 ]]'
check "unknown everywhere errors" '! "$AS" nope 2>/dev/null'
check "remove profile" '"$AS" codex remove personal 2>/dev/null && ! "$AS" codex list | grep -q personal'
check "remove leaves login alone" '[[ "$(codex_token)" == cB ]]'
check "store is private" '[[ "$(mode_of "$T/.ai-switch")" == 700 ]]'

echo
if (( fails )); then echo "$fails test(s) failed"; exit 1; fi
echo "all tests passed"
