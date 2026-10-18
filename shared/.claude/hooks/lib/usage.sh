#!/usr/bin/env bash
# Answers one question for the session gates: is further work in this session
# still covered by the plan's included windows, or is it already being paid out
# of usage credits? Source this; do not execute it.
#
# The answer comes from the account-wide usage endpoint, cached briefly so that
# several gates firing in one turn cost one request at most.

USAGE_ENDPOINT="https://api.anthropic.com/api/oauth/usage"
USAGE_CACHE="${TMPDIR:-/tmp}/claude-usage-utilization.json"
USAGE_CACHE_TTL=60

# Peak window utilization, in percent, at or above which further work is
# treated as credit-funded. Lower it to stop before the plan window runs dry.
USAGE_CREDIT_PCT=100

# While this file exists and is newer than its TTL, the prompt gate stands down.
USAGE_OVERRIDE="${TMPDIR:-/tmp}/claude-usage-credits-allowed"
USAGE_OVERRIDE_TTL=14400

usage_file_age() {
  local mtime
  mtime=$(stat -f %m "$1" 2>/dev/null || stat -c %Y "$1" 2>/dev/null) || return 1
  printf '%s' "$(( $(date +%s) - mtime ))"
}

usage_token() {
  local tok=""
  if [ -r "$HOME/.claude/.credentials.json" ]; then
    tok=$(jq -r '.claudeAiOauth.accessToken // empty' "$HOME/.claude/.credentials.json" 2>/dev/null)
  fi
  if [ -z "$tok" ]; then
    tok=$(security find-generic-password -s "Claude Code-credentials" -a "$USER" -w 2>/dev/null |
      jq -r '.claudeAiOauth.accessToken // empty' 2>/dev/null)
  fi
  printf '%s' "$tok"
}

usage_fetch() {
  local age tok tmp
  if [ -f "$USAGE_CACHE" ] && age=$(usage_file_age "$USAGE_CACHE") && [ "$age" -lt "$USAGE_CACHE_TTL" ]; then
    cat "$USAGE_CACHE"
    return 0
  fi
  tok=$(usage_token)
  [ -n "$tok" ] || return 1
  tmp="$USAGE_CACHE.$$"
  if ! curl -fsS --max-time 5 "$USAGE_ENDPOINT" \
    -H "Authorization: Bearer $tok" \
    -H "anthropic-beta: oauth-2025-04-20" >"$tmp" 2>/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$USAGE_CACHE"
  cat "$USAGE_CACHE"
}

# Highest utilization across every rate-limit window, normalised to percent.
usage_peak_pct() {
  jq -r '
    def pct: if . == null then empty elif . <= 1 then . * 100 else . end;
    ( [ (.limits // [])[]? | .percent // empty ]
      + [ .five_hour, .seven_day, .seven_day_opus, .seven_day_sonnet, .seven_day_oauth_apps
          | select(. != null) | .utilization | pct ]
      | max ) // empty
  ' 2>/dev/null
}

# "within" | "credits" | "unknown"
usage_state() {
  local body peak
  body=$(usage_fetch) || { printf 'unknown'; return; }
  peak=$(printf '%s' "$body" | usage_peak_pct)
  [ -n "$peak" ] || { printf 'unknown'; return; }
  awk -v p="$peak" -v t="$USAGE_CREDIT_PCT" 'BEGIN { print (p + 0 >= t + 0) ? "credits" : "within" }'
}

usage_summary() {
  usage_fetch 2>/dev/null | jq -r '
    def pct: if . == null then "?" else (if . <= 1 then . * 100 else . end | floor | tostring) + "%" end;
    "5h " + (.five_hour.utilization | pct)
    + " · 7d " + (.seven_day.utilization | pct)
    + (if .extra_usage.is_enabled then
         " · credits " + ((.extra_usage.used_credits // 0) | tostring)
         + (if .extra_usage.monthly_limit then "/" + (.extra_usage.monthly_limit | tostring) else "" end)
       else " · credits off" end)
  ' 2>/dev/null
}

usage_override_active() {
  local age
  [ -f "$USAGE_OVERRIDE" ] || return 1
  age=$(usage_file_age "$USAGE_OVERRIDE") || return 1
  [ "$age" -lt "$USAGE_OVERRIDE_TTL" ]
}
