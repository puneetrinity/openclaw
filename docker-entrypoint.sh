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
cat > "$CONFIG_FILE" << 'EOFCONFIG'
{
  "gateway": {
    "mode": "local",
    "trustedProxies": ["10.0.0.0/8", "100.64.0.0/10", "172.16.0.0/12", "192.168.0.0/16"]
  }
}
EOFCONFIG
chown node:node "$CONFIG_FILE" 2>/dev/null || true

# Drop to node user and exec the command
exec gosu node "$@"
