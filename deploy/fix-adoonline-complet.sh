#!/bin/bash
# Fix complet adoonline.click — PHP memoire + 502 + Nginx (renova intact)
set -e

echo "=== A. PHP-FPM ==="
apt update -qq
apt install -y php-fpm nginx

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.3")
PHP_INI="/etc/php/${PHP_VER}/fpm/php.ini"
PHP_SOCK=$(ls /var/run/php/*.sock 2>/dev/null | head -1)

[ -f "$PHP_INI" ] && sed -i 's/^memory_limit = .*/memory_limit = 1024M/' "$PHP_INI"
[ -f "$PHP_INI" ] && sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"

systemctl enable php${PHP_VER}-fpm nginx 2>/dev/null || true
systemctl restart php${PHP_VER}-fpm 2>/dev/null || systemctl restart php*-fpm
echo "Socket: $PHP_SOCK"

echo "=== B. Patch blackpage/index.php (memoire) ==="
BP="/var/www/blackpage/index.php"
if [ -f "$BP" ]; then
  grep -q 'ini_set.*memory_limit' "$BP" || \
    sed -i '1s/<?php/<?php\nini_set("memory_limit","1024M");\nini_set("max_execution_time","300");/' "$BP"
  echo "memory_limit = 1024M" > /var/www/blackpage/.user.ini
  chown www-data:www-data /var/www/blackpage/.user.ini 2>/dev/null || true
else
  echo "ERREUR: $BP absent"
  exit 1
fi

echo "=== C. Nginx blackpage (adoonline) ==="
cat > /etc/nginx/sites-available/blackpage << NGINXEOF
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
    root /var/www/blackpage;
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    client_max_body_size 20M;
    fastcgi_read_timeout 300;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_read_timeout 300;
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/adoonline.conf
ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage

echo "=== D. SSL ==="
certbot install --cert-name adoonline.click 2>/dev/null || \
  certbot --nginx -d adoonline.click -d www.adoonline.click \
    --non-interactive --agree-tos -m contact@renova-conseil.com --redirect 2>/dev/null || true

echo "=== E. Redemarrage ==="
nginx -t
systemctl reload nginx
systemctl restart php${PHP_VER}-fpm 2>/dev/null || systemctl restart php*-fpm

echo "=== F. Tests (max 30s) ==="
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo -n "adoonline HEAD: "
curl -skI --max-time 15 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo "adoonline body (5 lignes):"
curl -sk --max-time 20 https://127.0.0.1 -H "Host: adoonline.click" 2>/dev/null | head -5
echo "---"
echo "PHP errors:"
tail -5 /var/log/php${PHP_VER}-fpm.log 2>/dev/null || tail -5 /var/log/nginx/error.log 2>/dev/null || true
echo "=== TERMINE adoonline ==="
