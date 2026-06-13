#!/bin/bash
# Reparation directe adoonline.click
set -e
BP="/var/www/blackpage"
PHP_SOCK="/var/run/php/php8.3-fpm.sock"
[ -S "$PHP_SOCK" ] || PHP_SOCK="/var/run/php/php-fpm.sock"

cd "$BP"
[ -f index2.php ] && [ ! -f index2.php.disabled ] && mv index2.php index2.php.disabled
[ -f index.html ] && [ ! -s index.html ] && rm -f index.html

if [ -f index.php ]; then
  sed -i 's/class Hoaxer/if (!class_exists("Hoaxer")) class Hoaxer/' index.php
  sed -i 's/require (/require_once (/g; s/include (/include_once (/g' index.php 2>/dev/null || true
fi

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i 's/^memory_limit = .*/memory_limit = 1024M/' "/etc/php/${PHP_VER}/fpm/php.ini" 2>/dev/null || true
echo "memory_limit = 1024M" > "${BP}/.user.ini"
chown -R www-data:www-data "$BP"
systemctl restart php${PHP_VER}-fpm nginx 2>/dev/null || systemctl restart php8.3-fpm nginx

for f in /etc/nginx/sites-enabled/*; do
  b=$(basename "$f")
  case "$b" in blackpage|renova-conseil.conf) ;; *) rm -f "$f" ;; esac
done

cat > /etc/nginx/sites-available/blackpage << EOF
server {
    listen 80;
    listen [::]:80;
    server_name adoonline.click www.adoonline.click;
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name adoonline.click www.adoonline.click;
    root ${BP};
    index index.php;
    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_read_timeout 300;
    }
}
EOF
ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage
nginx -t && systemctl reload nginx
echo "BODY=$(curl -sk --max-time 45 https://127.0.0.1/ -H 'Host: adoonline.click' | wc -c)"
curl -skI https://127.0.0.1 -H "Host: adoonline.click" | head -1
curl -skI https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
