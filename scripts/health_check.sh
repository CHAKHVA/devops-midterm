#!/usr/bin/env bash

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVE_SLOT_FILE="$PROJECT_ROOT/active_slot"
LOG_FILE="$PROJECT_ROOT/logs/health.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

BLUE_PORT=5002
GREEN_PORT=5003

# ── Determine active port ─────────────────────────────────────────────────────
if [[ ! -f "$ACTIVE_SLOT_FILE" ]]; then
  echo "[$TIMESTAMP] ERROR - active_slot file not found" >>"$LOG_FILE"
  exit 1
fi

ACTIVE_SLOT=$(cat "$ACTIVE_SLOT_FILE")
if [[ "$ACTIVE_SLOT" == "blue" ]]; then
  PORT=$BLUE_PORT
else
  PORT=$GREEN_PORT
fi

# ── Health check ──────────────────────────────────────────────────────────────
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  --max-time 5 "http://localhost:$PORT/health" 2>/dev/null)

if [[ "$HTTP_STATUS" == "200" ]]; then
  echo "[$TIMESTAMP] OK   - App is healthy | slot=$ACTIVE_SLOT port=$PORT" >>"$LOG_FILE"
else
  echo "[$TIMESTAMP] FAIL - App is down    | slot=$ACTIVE_SLOT port=$PORT | HTTP $HTTP_STATUS" >>"$LOG_FILE"
fi
