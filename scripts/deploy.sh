#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ACTIVE_SLOT_FILE="$PROJECT_ROOT/active_slot"
DEPLOYMENTS="$PROJECT_ROOT/deployments"
VENV="$PROJECT_ROOT/venv"
NGINX_CONF="/opt/homebrew/etc/nginx/servers/midterm.conf"

BLUE_PORT=5002
GREEN_PORT=5003

# ── Read current state ────────────────────────────────────────────────────────
ACTIVE_SLOT=$(cat "$ACTIVE_SLOT_FILE")
if [[ "$ACTIVE_SLOT" == "blue" ]]; then
    INACTIVE_SLOT="green"
    INACTIVE_PORT=$GREEN_PORT
else
    INACTIVE_SLOT="blue"
    INACTIVE_PORT=$BLUE_PORT
fi

echo "============================================"
echo " Blue-Green Deploy"
echo "============================================"
echo "  Current active : $ACTIVE_SLOT"
echo "  Deploying to   : $INACTIVE_SLOT (port $INACTIVE_PORT)"
echo "--------------------------------------------"

# ── Copy latest source to inactive slot ──────────────────────────────────────
echo "[1/5] Copying source to $INACTIVE_SLOT slot..."
cp -r "$PROJECT_ROOT/src/" "$DEPLOYMENTS/$INACTIVE_SLOT/src/"
cp "$PROJECT_ROOT/requirements.txt" "$DEPLOYMENTS/$INACTIVE_SLOT/requirements.txt"

# ── Stop existing process on inactive port ────────────────────────────────────
echo "[2/5] Stopping any existing process on port $INACTIVE_PORT..."
if lsof -ti tcp:"$INACTIVE_PORT" &>/dev/null; then
    kill "$(lsof -ti tcp:"$INACTIVE_PORT")" 2>/dev/null || true
    sleep 1
fi

# ── Start Flask on inactive slot ──────────────────────────────────────────────
echo "[3/5] Starting Flask on port $INACTIVE_PORT..."
PORT=$INACTIVE_PORT "$VENV/bin/python" "$DEPLOYMENTS/$INACTIVE_SLOT/src/main.py" \
    > "$PROJECT_ROOT/logs/${INACTIVE_SLOT}.log" 2>&1 &
echo $! > "$DEPLOYMENTS/${INACTIVE_SLOT}.pid"
sleep 2

# ── Health check ──────────────────────────────────────────────────────────────
echo "[4/5] Health checking http://localhost:$INACTIVE_PORT/health ..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    "http://localhost:$INACTIVE_PORT/health" || echo "000")

if [[ "$HTTP_STATUS" != "200" ]]; then
    echo "ERROR: Health check failed (HTTP $HTTP_STATUS). Rolling back."
    kill "$(cat "$DEPLOYMENTS/${INACTIVE_SLOT}.pid")" 2>/dev/null || true
    rm -f "$DEPLOYMENTS/${INACTIVE_SLOT}.pid"
    exit 1
fi
echo "       Health check passed (HTTP 200)."

# ── Switch nginx upstream ─────────────────────────────────────────────────────
echo "[5/5] Switching nginx to $INACTIVE_SLOT (port $INACTIVE_PORT)..."
cat > "$NGINX_CONF" <<EOF
upstream app {
    server 127.0.0.1:${INACTIVE_PORT};
}

server {
    listen 80;
    server_name localhost;

    location / {
        proxy_pass http://app;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

sudo nginx -s reload

# ── Update active slot ────────────────────────────────────────────────────────
echo "$INACTIVE_SLOT" > "$ACTIVE_SLOT_FILE"

echo "--------------------------------------------"
echo " Deploy complete!"
echo "  Active slot : $INACTIVE_SLOT (port $INACTIVE_PORT)"
echo "  App URL     : http://localhost"
echo "============================================"
