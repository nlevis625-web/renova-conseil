#!/bin/bash
# Restaurer adoonline.click comme avant — PHP index.php original
# Ne touche PAS renova-conseil.com
set -e

BP="/var/www/blackpage"
PHP_SOCK="/var/run/php/php8.3-fpm.sock"
[ -S "$PHP_SOCK" ] || PHP_SOCK="/var/run/php/php-fpm.sock"

echo "=== 1. Sauvegarde ==="
cd "$BP"
ts=$(date +%s)
cp -a index.php "index.php.bak.$ts" 2>/dev/null || true
cp -a index2.php "index2.php.bak.$ts" 2>/dev/null || true

echo "=== 2. Restaurer index.php original ==="
# index2.php cause conflit Hoaxer — desactiver, garder index.php seul
if [ -f index2.php ]; then
  mv index2.php index2.php.disabled
  echo "index2.php desactive (conflit Hoaxer)"
fi

# Patch securite classe Hoaxer sur index.php
if grep -q 'class Hoaxer' index.php 2>/dev/null; then
  sed -i 's/class Hoaxer/if (!class_exists("Hoaxer")) class Hoaxer/' index.php
  sed -i "s/require '/require_once '/g; s/require \"/require_once \"/g" index.php
  sed -i "s/include '/include_once '/g; s/include \"/include_once \"/g" index.php
fi

echo "=== 3. PHP-FPM ==="
apt install -y php-fpm nginx -qq
PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i 's/^memory_limit = .*/memory_limit = 1024M/' "/etc/php/${PHP_VER}/fpm/php.ini"
sed -i 's/^max_execution_time = .*/max_execution_time = 300/' "/etc/php/${PHP_VER}/fpm/php.ini"
echo "memory_limit = 1024M" > "${BP}/.user.ini"
chown -R www-data:www-data "$BP"
systemctl restart php${PHP_VER}-fpm nginx

echo "=== 4. Nginx — adoonline seul (supprimer doublons) ==="
for f in /etc/nginx/sites-enabled/*; do
  base=$(basename "$f")
  case "$base" in
    blackpage|renova-conseil.conf) ;;
    *) rm -f "$f" ;;
  esac
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
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

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
EOF

ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage
certbot install --cert-name adoonline.click 2>/dev/null || true
nginx -t && systemctl reload nginx

echo "=== 5. Tests ==="
BODY=$(curl -sk --max-time 45 https://127.0.0.1/ -H "Host: adoonline.click" | wc -c)
echo "adoonline body: ${BODY} octets"
echo -n "adoonline: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1

if [ "$BODY" -lt 1000 ]; then
  echo "ATTENTION: page petite — logs:"
  tail -3 /var/log/nginx/error.log 2>/dev/null || true
fi

echo "=== RESTAURATION TERMINEE ==="
echo "adoonline.click = index.php PHP (comme avant)"
