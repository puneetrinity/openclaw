#!/bin/sh
set -e

# Fix volume permissions for /data if mounted
if [ -d "/data" ]; then
  # Create subdirectories and fix ownership (runs as root if needed)
  mkdir -p /data/.openclaw /data/workspace 2>/dev/null || true
  chown -R node:node /data 2>/dev/null || true
fi

# Drop to node user and exec the command
exec gosu node "$@"
