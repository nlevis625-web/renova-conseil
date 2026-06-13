#!/bin/bash
# FIX 502 adoonline.click — diagnostic + reparation complete
set -e

echo "========== DIAGNOSTIC =========="
systemctl is-active nginx || true
systemctl is-active php8.3-fpm 2>/dev/null || systemctl is-active php*-fpm 2>/dev/null || echo "PHP-FPM INACTIF"
ls -la /var/run/php/ 2>/dev/null || echo "PAS DE SOCKET PHP"
ls -la /var/www/blackpage/index.php 2>/dev/null || echo "INDEX.PHP ABSENT"

echo "========== INSTALL / REDEMARRAGE PHP =========="
apt update -qq
apt install -y php-fpm php-cli php-mbstring php-xml php-curl nginx

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
PHP_INI="/etc/php/${PHP_VER}/fpm/php.ini"
sed -i 's/^memory_limit = .*/memory_limit = 1024M/' "$PHP_INI"
sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "$PHP_INI"

systemctl enable php${PHP_VER}-fpm nginx
systemctl restart php${PHP_VER}-fpm
sleep 2

PHP_SOCK=$(ls /var/run/php/php${PHP_VER}-fpm.sock 2>/dev/null || ls /var/run/php/*.sock | head -1)
echo "SOCKET UTILISE: $PHP_SOCK"
test -S "$PHP_SOCK" || { echo "ERREUR: socket PHP introuvable"; exit 1; }

echo "========== PERMISSIONS BLACKPAGE =========="
chown -R www-data:www-data /var/www/blackpage
chmod -R 755 /var/www/blackpage
echo "memory_limit = 1024M" > /var/www/blackpage/.user.ini
chown www-data:www-data /var/www/blackpage/.user.ini

echo "========== PATCH index.php =========="
BP="/var/www/blackpage/index.php"
if [ -f "$BP" ]; then
  cp -a "$BP" "${BP}.bak.$(date +%s)"
  grep -q 'ini_set.*memory_limit' "$BP" || \
    sed -i '1s/<?php/<?php\nini_set("memory_limit","1024M");\nini_set("max_execution_time","300");/' "$BP"
fi

echo "========== TEST PHP CLI =========="
timeout 10 php -d memory_limit=1024M "$BP" 2>&1 | head -8 || echo "PHP CLI timeout ou erreur"

echo "========== NGINX BLACKPAGE =========="
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

    fastcgi_read_timeout 300;
    fastcgi_buffers 16 16k;
    fastcgi_buffer_size 32k;

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

echo "========== NGINX RENOVA (socket PHP corrige) =========="
if [ -f /etc/nginx/sites-available/renova-conseil.conf ]; then
  sed -i "s|fastcgi_pass unix:.*|fastcgi_pass unix:${PHP_SOCK};|g" /etc/nginx/sites-available/renova-conseil.conf
fi

nginx -t
systemctl restart nginx

echo "========== TESTS =========="
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo -n "adoonline: "
curl -skI --max-time 15 https://127.0.0.1 -H "Host: adoonline.click" | head -1

echo "========== LOGS SI ECHEC =========="
tail -8 /var/log/nginx/error.log 2>/dev/null || true
echo "========== FIN =========="
