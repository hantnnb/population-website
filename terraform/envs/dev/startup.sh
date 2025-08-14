#!/bin/bash

# Update OS and install system dependencies
apt-get update && apt-get install -y \
  python3 python3-pip python3-venv git build-essential \
  libgeos-dev libproj-dev gdal-bin libgdal-dev \
  curl nginx software-properties-common \
  certbot python3-certbot-nginx

# Symlink python
ln -s /usr/bin/python3 /usr/bin/python

# Install Node.js (for PM2)
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs 

# Install PM2 globally
npm install -g pm2

# Clone the repository
cd /opt
git clone -b stg https://github.com/hantnnb/population-website.git /opt/population-website
chown -R ubuntu:ubuntu /opt/population-website  # Chuyển quyền cho user ubuntu

# Wait until the folder exists (cẩn thận race condition)
while [ ! -d /opt/population-website ]; do sleep 1; done

# Ghi nội dung metadata vào file .env
curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_file \
  -o /opt/population-website/population/.env

curl -s -H "Metadata-Flavor: Google" \
  http://metadata.google.internal/computeMetadata/v1/instance/attributes/env_backend \
  -o /opt/population-website/population/backend/.env

# Chạy tất cả dưới quyền user ubuntu
sudo -i -u ubuntu bash <<'EOF'
# Tạo venv và cài Python packages
cd /opt/population-website
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install Flask Flask-PyMongo Flask-Session dash geopandas plotly gunicorn python-dotenv flask_cors

# Chạy Flask app bằng gunicorn (qua PM2)
pm2 start "venv/bin/gunicorn app:app --bind 127.0.0.1:5000 --workers 3" \
  --name population-website \
  --interpreter none

# Cài thư viện Node.js & khởi động backend
cd /opt/population-website/population/backend
npm init -y
npm install express dotenv axios
pm2 start server.js --name backend --watch

# Lưu cấu hình và enable auto-restart
pm2 save
pm2 startup systemd
EOF

# Chạy lệnh startup được PM2 gợi ý (phía root)
sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u ubuntu --hp /home/ubuntu

# Install Nginx
apt-get install -y nginx

# Create Nginx reverse proxy
cat <<EOF > /etc/nginx/sites-available/pplt
server {
    listen 80;
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

# Active website site
ln -s /etc/nginx/sites-available/pplt /etc/nginx/sites-enabled/

# Create vhost for api.vnpop.thonh.site
cat <<EOF > /etc/nginx/sites-available/api.pplt-dev.vitlab.site
server {
    listen 80;
    server_name api-dev.pplt-dev.vitlab.site;

    location / {
        proxy_pass http://127.0.0.1:5001;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF

# Active api.vnpop.thonh.site site
ln -s /etc/nginx/sites-available/api.pplt-dev.vitlab.site /etc/nginx/sites-enabled/
rm /etc/nginx/sites-enabled/default
systemctl restart nginx

# Request SSL certs from Let's Encrypt (Make sure DNS is already updated)
certbot --nginx --non-interactive --agree-tos \
  -m han.tnnb@gmail.com \
  -d pplt-dev.vitlab.site \
  -d api-dev.pplt-dev.vitlab.site

# Add cron job for auto-renew
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/certbot renew --quiet --deploy-hook 'systemctl reload nginx'") | crontab -

# CI/CD here