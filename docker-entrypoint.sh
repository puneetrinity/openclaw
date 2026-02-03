#!/bin/sh
set -e

# Fix volume permissions for /data if mounted
if [ -d "/data" ]; then
  if [ -z "${OPENCLAW_STATE_DIR:-}" ]; then
    export OPENCLAW_STATE_DIR="/data/.openclaw"
  fi

  # Create subdirectories and fix ownership (runs as root if needed)
  mkdir -p \
    "${OPENCLAW_STATE_DIR}" \
    /data/workspace \
    /data/workspace-puneet \
    /data/workspace-family2 \
    2>/dev/null || true
  chown -R node:node /data 2>/dev/null || true
fi

# Create config with trusted proxies for reverse proxy environments (Railway, etc.)
CONFIG_DIR="${OPENCLAW_STATE_DIR:-/home/node/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true

# Optional: disable Control UI device pairing (trusts token-only auth)
CONTROL_UI_DISABLE_DEVICE_AUTH=false
if [ "${OPENCLAW_CONTROL_UI_DISABLE_DEVICE_AUTH:-}" = "1" ] || \
  [ "${OPENCLAW_CONTROL_UI_DISABLE_DEVICE_AUTH:-}" = "true" ]; then
  CONTROL_UI_DISABLE_DEVICE_AUTH=true
fi

# Always recreate config to ensure trustedProxies is set (volume may have old config)
# Note: trustedProxies requires exact IPs (no CIDR support)
# Railway uses 100.64.0.x range for internal proxies
cat > "$CONFIG_FILE" << EOFCONFIG
{
  "gateway": {
    "mode": "local",
    "trustedProxies": [
      "100.64.0.1", "100.64.0.2", "100.64.0.3", "100.64.0.4", "100.64.0.5",
      "100.64.0.6", "100.64.0.7", "100.64.0.8", "100.64.0.9", "100.64.0.10",
      "100.64.0.11", "100.64.0.12", "100.64.0.13", "100.64.0.14", "100.64.0.15",
      "100.64.0.16", "100.64.0.17", "100.64.0.18", "100.64.0.19", "100.64.0.20"
    ],
    "controlUi": {
      "enabled": true,
      "dangerouslyDisableDeviceAuth": ${CONTROL_UI_DISABLE_DEVICE_AUTH}
    }
  },
  "agents": {
    "defaults": {
      "model": {
        "primary": "google/gemini-2.0-flash"
      }
    },
    "list": [
      { "id": "puneet", "default": true, "workspace": "/data/workspace-puneet", "name": "Puneet" },
      { "id": "family2", "workspace": "/data/workspace-family2", "name": "Family 2" }
    ]
  },
  "bindings": [
    {
      "agentId": "puneet",
      "match": { "channel": "telegram", "peer": { "kind": "dm", "id": "${PUNEET_TELEGRAM_ID:-000000000}" } }
    },
    {
      "agentId": "family2",
      "match": { "channel": "telegram", "peer": { "kind": "dm", "id": "${FAMILY2_TELEGRAM_ID:-000000001}" } }
    }
  ],
  "session": {
    "dmScope": "per-channel-peer"
  },
  "channels": {
    "telegram": {
      "dmPolicy": "allowlist",
      "allowFrom": [
        "${PUNEET_TELEGRAM_ID:-000000000}",
        "${FAMILY2_TELEGRAM_ID:-000000001}"
      ]
    }
  }
}
EOFCONFIG
chown node:node "$CONFIG_FILE" 2>/dev/null || true

# Drop to node user and exec the command
exec gosu node "$@"
