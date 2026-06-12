#!/bin/bash
# Installation complète renova-conseil.com — à lancer sur le Droplet (root)
set -e

export DEBIAN_FRONTEND=noninteractive

echo "=== 1. Arreter Apache (conflit port 80) ==="
systemctl stop apache2 2>/dev/null || true
systemctl disable apache2 2>/dev/null || true

echo "=== 2. Installer Nginx + PHP + Git + Certbot ==="
apt update -qq
apt install -y nginx php-fpm git certbot python3-certbot-nginx

echo "=== 3. Telecharger le site ==="
rm -rf /var/www/renova-conseil
git clone https://github.com/nlevis625-web/renova-conseil.git /var/www/renova-conseil
test -f /var/www/renova-conseil/index.php

echo "=== 4. Config Nginx ==="
PHP_SOCK=$(ls /var/run/php/*.sock | head -1)
echo "PHP socket: $PHP_SOCK"

mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

cat > /etc/nginx/sites-available/renova-conseil.conf << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name renova-conseil.com www.renova-conseil.com;
    root /var/www/renova-conseil;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/renovia*
rm -f /etc/nginx/sites-enabled/adoonline*
rm -f /etc/nginx/sites-enabled/pop3
ln -sf /etc/nginx/sites-available/renova-conseil.conf /etc/nginx/sites-enabled/

echo "=== 5. Demarrer services ==="
nginx -t
systemctl enable nginx
systemctl restart nginx
systemctl restart php*-fpm 2>/dev/null || systemctl restart php8.3-fpm

echo "=== 6. Test HTTP ==="
curl -sI http://127.0.0.1 -H "Host: renova-conseil.com" | head -1

echo "=== 7. SSL Let's Encrypt ==="
certbot --nginx -d renova-conseil.com -d www.renova-conseil.com \
  --non-interactive --agree-tos -m contact@renova-conseil.com --redirect || \
certbot install --cert-name renova-conseil.com

nginx -t && systemctl reload nginx

echo "=== 8. Test HTTPS ==="
curl -skI https://127.0.0.1 -H "Host: renova-conseil.com" | head -1

echo ""
echo "=== TERMINE ==="
echo "Site: https://renova-conseil.com"
echo "Purge cache Cloudflare puis Ctrl+Shift+R dans le navigateur."
