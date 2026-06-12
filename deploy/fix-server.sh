#!/bin/bash
# Réparation serveur renova-conseil.com — à lancer sur le Droplet (console DigitalOcean)
set -e
apt update -qq && apt install -y nginx php-fpm git certbot python3-certbot-nginx

mkdir -p /var/www/renova-conseil
cd /var/www/renova-conseil
test -f index.php || git clone https://github.com/nlevis625-web/renova-conseil.git .

PHP_SOCK=$(ls /var/run/php/*.sock | head -1)

cat > /etc/nginx/sites-available/renova-conseil.conf << EOF
server {
    listen 80;
    listen [::]:80;
    server_name renova-conseil.com www.renova-conseil.com;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name renova-conseil.com www.renova-conseil.com;
    root /var/www/renova-conseil;
    index index.php index.html;
    ssl_certificate /etc/letsencrypt/live/renova-conseil.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/renova-conseil.com/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \\.php\$ { include snippets/fastcgi-php.conf; fastcgi_pass unix:${PHP_SOCK}; }
}
EOF

rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/renovia* /etc/nginx/sites-enabled/adoonline*
ln -sf /etc/nginx/sites-available/renova-conseil.conf /etc/nginx/sites-enabled/

if [ ! -f /etc/letsencrypt/live/renova-conseil.com/fullchain.pem ]; then
  certbot --nginx -d renova-conseil.com -d www.renova-conseil.com \
    --non-interactive --agree-tos -m contact@renova-conseil.com --redirect
fi

systemctl restart nginx php*-fpm
echo "=== TEST ==="
curl -Ik https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
