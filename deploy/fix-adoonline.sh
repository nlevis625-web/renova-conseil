#!/bin/bash
# Repare adoonline.click SANS toucher renova-conseil.com
set -e

echo "=== 1. Verifier renova (ne pas casser) ==="
curl -sI http://127.0.0.1 -H "Host: renova-conseil.com" | head -1

echo "=== 2. Site adoonline ==="
ls -la /var/www/blackpage/index.php

echo "=== 3. Augmenter memoire PHP ==="
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.3")
PHP_INI="/etc/php/${PHP_VER}/fpm/php.ini"
if [ -f "$PHP_INI" ]; then
  sed -i 's/^memory_limit = .*/memory_limit = 512M/' "$PHP_INI" || true
  grep -q '^memory_limit' "$PHP_INI" || echo 'memory_limit = 512M' >> "$PHP_INI"
fi
echo "memory_limit = 512M" > /var/www/blackpage/.user.ini
chown www-data:www-data /var/www/blackpage/.user.ini 2>/dev/null || true

echo "=== 4. Config Nginx adoonline (separe de renova) ==="
PHP_SOCK=$(ls /var/run/php/*.sock | head -1)

cat > /etc/nginx/sites-available/adoonline.conf << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name adoonline.click www.adoonline.click;
    root /var/www/blackpage;
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

ln -sf /etc/nginx/sites-available/adoonline.conf /etc/nginx/sites-enabled/adoonline.conf

echo "=== 5. SSL adoonline (si certificat existe) ==="
if [ -d /etc/letsencrypt/live/adoonline.click ]; then
  certbot install --cert-name adoonline.click 2>/dev/null || true
else
  certbot --nginx -d adoonline.click -d www.adoonline.click \
    --non-interactive --agree-tos -m contact@renova-conseil.com --redirect 2>/dev/null || true
fi

echo "=== 6. Redemarrer services ==="
nginx -t
systemctl reload nginx
systemctl restart php${PHP_VER}-fpm 2>/dev/null || systemctl restart php*-fpm

echo "=== 7. Tests ==="
echo -n "renova: "
curl -sI http://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo -n "adoonline: "
curl -sI http://127.0.0.1 -H "Host: adoonline.click" | head -1
curl -skI https://127.0.0.1 -H "Host: adoonline.click" 2>/dev/null | head -1 || true

echo "=== TERMINE adoonline ==="
