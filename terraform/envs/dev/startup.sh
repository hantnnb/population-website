#!/bin/bash

# Update OS and install system dependencies
apt-get update && apt-get install -y \
  python3 python3-pip python3-venv build-essential \
  curl nginx software-properties-common \
  nodejs npm

# Optional: Symlink python
ln -sf /usr/bin/python3 /usr/bin/python

# Install Node.js (PM2 needs it)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs 

# Install PM2 globally
npm install -g pm2

# Clone App code, private => need token
git clone https://github.com/hantnnb/population-website.git /opt/population-website
chown -R ubuntu:ubuntu /opt/population-website

# Wait until the folder exists
while [ ! -d /opt/population-website ]; do sleep 1; done

# Inject metadata into .env files
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_file \
  -o /opt/population-website/population/.env

curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_backend \
  -o /opt/population-website/population/backend/.env

# Switch to ubuntu user
sudo -i -u ubuntu bash <<'EOF'
cd /opt/population-website/population

# Python virtual environment setup
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install Flask Flask-PyMongo Flask-Session dash geopandas plotly gunicorn python-dotenv flask_cors

# Start Flask app via Gunicorn
pm2 start "venv/bin/gunicorn app:app --bind 127.0.0.1:5000 --workers 3" \
  --name flask-app --interpreter none

# Start Node.js backend
cd /opt/population-website/population/backend
npm install express dotenv axios
pm2 start server.js --name backend --watch

# Save and auto-start
pm2 save
pm2 startup systemd
EOF

# Run the PM2 startup suggestion (from root)
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

# 🔁 Setup Nginx reverse proxy

# Frontend (Flask app)
cat <<EOF > /etc/nginx/sites-available/pplt-dev
server {
    listen 80 default_server;
    server_name pplt-dev.vitlab.site;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Backend (Node.js API)
cat <<EOF > /etc/nginx/sites-available/api
server {
    listen 80;
    server_name api.pplt-dev.vitlab.site;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Activate both configs
ln -sf /etc/nginx/sites-available/population /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Restart Nginx to apply
systemctl restart nginx