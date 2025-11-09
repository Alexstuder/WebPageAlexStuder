#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROXY_DIR="${ROOT_DIR}/proxy"

if [ ! -d "${PROXY_DIR}" ]; then
  echo "proxy directory not found at ${PROXY_DIR}" >&2
  exit 1
fi

cd "${PROXY_DIR}"

if [ ! -d "node_modules" ]; then
  echo "Installing proxy dependencies..."
  npm install
else
  echo "Proxy dependencies already installed (node_modules exists)."
fi

echo "Starting proxy (Ctrl+C to stop)..."
npm start
