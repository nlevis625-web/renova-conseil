#!/bin/bash
# Fix final adoonline — supprime doublons nginx + PHP index2.php
set -e

echo "=== 1. DOUBLONS NGINX ==="
ls -la /etc/nginx/sites-enabled/
grep -rl "adoonline.click" /etc/nginx/sites-enabled/ /etc/nginx/sites-available/ 2>/dev/null || true

# Garder UNIQUEMENT blackpage + renova-conseil
for f in /etc/nginx/sites-enabled/*; do
  base=$(basename "$f")
  case "$base" in
    blackpage|renova-conseil.conf) ;;
    *) rm -f "$f" ;;
  esac
done

echo "Apres nettoyage:"
ls -la /etc/nginx/sites-enabled/

BP="/var/www/blackpage"
PHP_SOCK="/var/run/php/php8.3-fpm.sock"
[ -S "$PHP_SOCK" ] || PHP_SOCK="/var/run/php/php-fpm.sock"

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
sed -i 's/^memory_limit = .*/memory_limit = 1024M/' "/etc/php/${PHP_VER}/fpm/php.ini"
echo "memory_limit = 1024M" > "${BP}/.user.ini"
systemctl restart php${PHP_VER}-fpm nginx

echo "=== 2. TEST PHP direct ==="
echo "--- index2.php (5 lignes) ---"
curl -s --max-time 30 http://127.0.0.1/index2.php -H "Host: adoonline.click" 2>/dev/null | head -5 || true
echo "--- index.php (5 lignes) ---"
curl -s --max-time 30 http://127.0.0.1/index.php -H "Host: adoonline.click" 2>/dev/null | head -5 || true

# Choisir le meilleur index
S2=$(curl -s --max-time 30 http://127.0.0.1/index2.php -H "Host: adoonline.click" 2>/dev/null | wc -c)
S1=$(curl -s --max-time 30 http://127.0.0.1/index.php -H "Host: adoonline.click" 2>/dev/null | wc -c)
echo "taille index2.php: $S2 | index.php: $S1"

if [ "$S1" -gt "$S2" ]; then
  INDEX="index.php"
else
  INDEX="index2.php"
fi
echo "Index choisi: $INDEX"

echo "=== 3. CONFIG NGINX UNIQUE ==="
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
    index ${INDEX} index.html;

    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    fastcgi_read_timeout 300;
    fastcgi_buffers 32 32k;
    fastcgi_buffer_size 64k;

    location / {
        try_files \$uri \$uri/ /${INDEX}?\$query_string;
    }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_read_timeout 300;
        fastcgi_param HTTP_HOST adoonline.click;
        fastcgi_param HTTPS on;
    }
}
EOF

ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage
nginx -t 2>&1 | grep -v "conflicting server name" || nginx -t
systemctl reload nginx

echo "=== 4. TESTS ==="
BODY=$(curl -sk --max-time 30 https://127.0.0.1/ -H "Host: adoonline.click" | wc -c)
echo "adoonline body: ${BODY} octets"
curl -sk --max-time 30 https://127.0.0.1/ -H "Host: adoonline.click" | head -3
echo "---"
echo -n "adoonline: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== PHP errors ==="
tail -5 /var/log/nginx/error.log 2>/dev/null || true
echo "=== FIN ==="
