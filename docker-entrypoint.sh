#!/bin/sh
set -e

# Fix volume permissions for /data if mounted
if [ -d "/data" ]; then
  # Create subdirectories and fix ownership (runs as root if needed)
  mkdir -p /data/.openclaw /data/workspace 2>/dev/null || true
  chown -R node:node /data 2>/dev/null || true
fi

# Create config with trusted proxies for reverse proxy environments (Railway, etc.)
CONFIG_DIR="${OPENCLAW_STATE_DIR:-/home/node/.openclaw}"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
mkdir -p "$CONFIG_DIR" 2>/dev/null || true

# Always recreate config to ensure trustedProxies is set (volume may have old config)
# Note: trustedProxies requires exact IPs (no CIDR support)
# Railway uses 100.64.0.x range for internal proxies
cat > "$CONFIG_FILE" << 'EOFCONFIG'
{
  "gateway": {
    "mode": "local",
    "trustedProxies": [
      "100.64.0.1", "100.64.0.2", "100.64.0.3", "100.64.0.4", "100.64.0.5",
      "100.64.0.6", "100.64.0.7", "100.64.0.8", "100.64.0.9", "100.64.0.10",
      "100.64.0.11", "100.64.0.12", "100.64.0.13", "100.64.0.14", "100.64.0.15",
      "100.64.0.16", "100.64.0.17", "100.64.0.18", "100.64.0.19", "100.64.0.20"
    ]
  }
}
EOFCONFIG
chown node:node "$CONFIG_FILE" 2>/dev/null || true

# Drop to node user and exec the command
exec gosu node "$@"
