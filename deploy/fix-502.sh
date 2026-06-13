#!/bin/bash
# Fix 502 Bad Gateway — renova + adoonline (PHP-FPM + sockets Nginx)
set -e

echo "=== 1. PHP-FPM ==="
apt update -qq
apt install -y php-fpm nginx

PHP_SOCK=$(ls /var/run/php/*.sock 2>/dev/null | head -1)
if [ -z "$PHP_SOCK" ]; then
  systemctl start php*-fpm 2>/dev/null || systemctl start php8.3-fpm
  sleep 2
  PHP_SOCK=$(ls /var/run/php/*.sock | head -1)
fi
echo "Socket PHP: $PHP_SOCK"
systemctl enable php*-fpm nginx 2>/dev/null || true
systemctl restart php*-fpm 2>/dev/null || systemctl restart php8.3-fpm
systemctl status php*-fpm --no-pager 2>/dev/null | head -3 || systemctl status php8.3-fpm --no-pager | head -3

echo "=== 2. Memoire PHP ==="
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo "8.3")
PHP_INI="/etc/php/${PHP_VER}/fpm/php.ini"
[ -f "$PHP_INI" ] && sed -i 's/^memory_limit = .*/memory_limit = 512M/' "$PHP_INI"
echo "memory_limit = 512M" > /var/www/renova-conseil/.user.ini 2>/dev/null || true
echo "memory_limit = 512M" > /var/www/blackpage/.user.ini 2>/dev/null || true
systemctl restart php${PHP_VER}-fpm 2>/dev/null || systemctl restart php*-fpm

echo "=== 3. Nginx renova-conseil ==="
cat > /etc/nginx/sites-available/renova-conseil.conf << NGINXEOF
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

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF

echo "=== 4. Nginx adoonline (blackpage) ==="
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

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/adoonline.conf
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/renova-conseil.conf /etc/nginx/sites-enabled/
ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/

echo "=== 5. Redemarrage ==="
nginx -t
systemctl restart nginx

echo "=== 6. Tests ==="
echo -n "renova: "
curl -skI https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo -n "adoonline: "
curl -skI https://127.0.0.1 -H "Host: adoonline.click" | head -1

echo "=== TERMINE ==="
