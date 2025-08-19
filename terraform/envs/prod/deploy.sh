#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="/opt/population-website"

cd "$REPO_DIR"

# 🔹 Pull latest code =====================================================
git fetch origin prod-test
git reset --hard origin/prod-test

# Refresh env files =======================================================
# Flask app env
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_file \
  -o "$REPO_DIR/population/.env"

# Node backend env
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_backend \
  -o "$REPO_DIR/population/backend/.env"

# Python deps =============================================================
cd population
python3 -m venv .venv
. .venv/bin/activate
pip install -U pip
[ -f requirements.txt ] && pip install -r requirements.txt
deactivate
cd ..

# Node deps ==============================================================
if [ -d population/backend ]; then
  cd population/backend
  if [ -f package-lock.json ]; then npm ci; else npm install; fi
  cd ../..
fi

# PM2 reload =============================================================
pm2 startOrReload "$REPO_DIR/ecosystem.config.js"
pm2 save