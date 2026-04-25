#!/bin/bash
# Entrypoint: find Chrome headless shell, set env var, start the worker

CHROME_PATH=$(find /root/.cache/puppeteer/chrome-headless-shell -name "chrome-headless-shell" -type f 2>/dev/null | head -1)

if [ -z "$CHROME_PATH" ]; then
  echo "ERROR: Chrome headless shell not found in /root/.cache/puppeteer/chrome-headless-shell"
  exit 1
fi

export PRODUCER_HEADLESS_SHELL_PATH="$CHROME_PATH"
echo "Chrome headless shell: $PRODUCER_HEADLESS_SHELL_PATH"

mkdir -p "${PRODUCER_RENDERS_DIR:-/tmp/renders}"

exec node dist/index.js
