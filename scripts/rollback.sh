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
    ROLLBACK_SLOT="green"
    ROLLBACK_PORT=$GREEN_PORT
else
    ROLLBACK_SLOT="blue"
    ROLLBACK_PORT=$BLUE_PORT
fi

echo "============================================"
echo " Blue-Green Rollback"
echo "============================================"
echo "  Current active  : $ACTIVE_SLOT"
echo "  Rolling back to : $ROLLBACK_SLOT (port $ROLLBACK_PORT)"
echo "--------------------------------------------"

# ── Ensure rollback slot is running ──────────────────────────────────────────
if ! lsof -ti tcp:"$ROLLBACK_PORT" &>/dev/null; then
    echo "[1/3] $ROLLBACK_SLOT is not running — starting it..."
    PORT=$ROLLBACK_PORT "$VENV/bin/python" "$DEPLOYMENTS/$ROLLBACK_SLOT/src/main.py" \
        > "$PROJECT_ROOT/logs/${ROLLBACK_SLOT}.log" 2>&1 &
    echo $! > "$DEPLOYMENTS/${ROLLBACK_SLOT}.pid"
    sleep 2

    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
        "http://localhost:$ROLLBACK_PORT/health" || echo "000")

    if [[ "$HTTP_STATUS" != "200" ]]; then
        echo "ERROR: Rollback slot failed health check (HTTP $HTTP_STATUS). Aborting."
        exit 1
    fi
else
    echo "[1/3] $ROLLBACK_SLOT is already running on port $ROLLBACK_PORT."
fi

# ── Switch nginx upstream ─────────────────────────────────────────────────────
echo "[2/3] Switching nginx to $ROLLBACK_SLOT (port $ROLLBACK_PORT)..."
cat > "$NGINX_CONF" <<EOF
upstream app {
    server 127.0.0.1:${ROLLBACK_PORT};
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
echo "[3/3] Updating active slot to $ROLLBACK_SLOT..."
echo "$ROLLBACK_SLOT" > "$ACTIVE_SLOT_FILE"

echo "--------------------------------------------"
echo " Rollback complete!"
echo "  Active slot : $ROLLBACK_SLOT (port $ROLLBACK_PORT)"
echo "  App URL     : http://localhost"
echo "============================================"
