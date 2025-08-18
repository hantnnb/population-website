#!/bin/bash
set -euo pipefail

# Basic setup =================================================================================
# Update OS and install system dependencies
apt-get update && apt-get install -y \
  python3 python3-pip python3-venv git build-essential \
  libgeos-dev libproj-dev gdal-bin libgdal-dev \
  curl nginx software-properties-common \
  certbot python3-certbot-nginx \
  nodejs npm rsync cron

# Symlink python - shortcut python = python3
ln -sf /usr/bin/python3 /usr/bin/python
# Add f for idempotent, replace if existed (avoid breaking script if ran multiple times)

# Node & PM2 - Add a check to see if node is installed => enhance speed by not reinstalling
if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
  apt-get install -y nodejs
fi
npm install -g pm2@latest

# Cloning Code =================================================================================
REPO_DIR="/opt/population-website"
BRANCH="stg"

mkdir -p "$REPO_DIR"
chown -R ubuntu:ubuntu "$REPO_DIR"

if [ ! -d "$REPO_DIR/.git" ]; then
  sudo -u ubuntu bash -lc "git clone -b '$BRANCH' https://github.com/hantnnb/population-website.git '$REPO_DIR'"
else
  sudo -u ubuntu bash -lc "
    cd '$REPO_DIR' &&
    git fetch origin '$BRANCH' &&
    git reset --hard 'origin/$BRANCH'
  "
fi

# Inject env files from vm metadata =============================================================
# Wait until the folder exists (avoid race condition)
while [ ! -d /opt/population-website ]; do sleep 1; done

# Flask app env
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_file \
  -o "$REPO_DIR/population/.env"

# Node backend env
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_backend \
  -o "$REPO_DIR/population/backend/.env"

# App setup =============================================================
sudo -iu ubuntu bash <<'EOSU'
set -euo pipefail
REPO_DIR="/opt/population-website"

# Create venv and install python packages
cd "$REPO_DIR/population"
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip

# Use requirements.txt if present; otherwise install known deps
if [ -f requirements.txt ]; then
  pip install -r requirements.txt
else
  pip install Flask Flask-PyMongo Flask-Session dash geopandas plotly gunicorn python-dotenv flask_cors
fi
deactivate

# Node backend deps - use package.json if exist, not overwrite
if [ -d "$REPO_DIR/population/backend" ]; then
  cd "$REPO_DIR/population/backend"
  if [ -f package-lock.json ]; then npm ci; else npm install; fi
fi

# Create/overwrite a PM2 ecosystem to manage both apps cleanly
# Avoid duplicate resources when rerun script (e.g, when using sudo reboot)
cat > "$REPO_DIR/ecosystem.config.js" <<'EOF'
module.exports = {
  apps: [
    {
      name: "flask",
      cwd: "/opt/population-website/population",
      script: ".venv/bin/gunicorn",
      args: "app:app -b 127.0.0.1:5000 --workers 3 --timeout 90",
      interpreter: "none",
      env: { NODE_ENV: "production" }
    },
    {
      name: "backend",
      cwd: "/opt/population-website/population/backend",
      script: "server.js",
      env: { NODE_ENV: "production", PORT: "5001" }
    }
  ]
}
EOF

# Start or reload both
cd "$REPO_DIR"
pm2 startOrReload ecosystem.config.js
pm2 save

# Enable PM2 on boot (once is enough)
pm2 startup systemd -u ubuntu --hp /home/ubuntu >/tmp/pm2_inst.txt || true
EOSU

# Ensure PM2 boot command applied for root/systemd context
if grep -q "sudo" /tmp/pm2_inst.txt 2>/dev/null; then
  bash /tmp/pm2_inst.txt || true
fi

# Nginx reverse proxies =============================================================
# Site: pplt-dev.vitlab.site -> Flask (5000)
cat <<EOF > /etc/nginx/sites-available/pplt-dev2
server {
    listen 80 default_server;
    server_name pplt-dev2.vitlab.site;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Active website site
ln -s /etc/nginx/sites-available/pplt-dev2 /etc/nginx/sites-enabled/

# API: api.pplt-dev.vitlab.site -> Node (5001)
cat <<EOF > /etc/nginx/sites-available/api.pplt-dev2.vitlab.site
server {
    listen 80;
    server_name api.pplt-dev2.vitlab.site;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

ln -sf /etc/nginx/sites-available/api.pplt-dev2.vitlab.site /etc/nginx/sites-enabled/api.pplt-dev2.vitlab.site

# Remove default, test and reload
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

# TLS (Let's Encrypt) =============================================================
# Install Google Cloud SDK (for gsutil)
if ! command -v gsutil >/dev/null 2>&1; then
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" \
    | tee /etc/apt/sources.list.d/google-cloud-sdk.list
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
  apt-get update && apt-get install -y google-cloud-cli
fi

# Restore certs from GCS 
GCS_BUCKET="gs://pplt-ssl-backups/letsencrypt"   # append /letsencrypt prefix
mkdir -p /etc/letsencrypt
gsutil -m rsync -r "$GCS_BUCKET/" /etc/letsencrypt/ || true

# === Issue only if needed =================================
LIVE_DIR=/etc/letsencrypt/live/pplt-dev.vitlab.site
NEAR_EXPIRY=false
if [ -f "$LIVE_DIR/fullchain.pem" ]; then
  if ! openssl x509 -in "$LIVE_DIR/fullchain.pem" -noout -checkend $((30*24*3600)) >/dev/null 2>&1; then
    NEAR_EXPIRY=true
  fi
fi

if [ ! -f "$LIVE_DIR/fullchain.pem" ] || [ "$NEAR_EXPIRY" = "true" ]; then
  STAGING="${STAGING:-0}"          
  if [ "$STAGING" = "1" ]; then
    CB_EXTRA="--staging"           
  else
    CB_EXTRA=""
  fi

  set +e
  certbot --nginx --non-interactive --agree-tos --keep-until-expiring --reuse-key \
    -m han.tnnb@gmail.com \
    -d pplt-dev2.vitlab.site -d api.pplt-dev2.vitlab.site \
    $CB_EXTRA
  CB_STATUS=$?
  set -e
  if [ $CB_STATUS -ne 0 ]; then
    echo "WARN: certbot initial issue failed ($CB_STATUS); continuing boot"
  fi
fi

# === Backup certs to GCS ===============================================
# Backup certs to GCS 
gsutil -m rsync -r /etc/letsencrypt/ "$GCS_BUCKET/"

# Renewal cron
( crontab -l 2>/dev/null || true; \
  echo "0 2 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'" \
) | crontab -