#!/bin/bash
# adoonline.click — PHP fonctionnel (capture HTML echoue)
set -e

BP="/var/www/blackpage"
PHP_SOCK="/var/run/php/php8.3-fpm.sock"
[ -S "$PHP_SOCK" ] || PHP_SOCK="/var/run/php/php-fpm.sock"
echo "Socket: $PHP_SOCK"

apt install -y php-fpm nginx -qq
echo "memory_limit = 1024M" > "${BP}/.user.ini"
chown www-data:www-data "${BP}/.user.ini"
systemctl restart php8.3-fpm nginx

# Supprimer tous les doublons
rm -f /etc/nginx/sites-enabled/adoonline.conf
rm -f /etc/nginx/sites-enabled/blackpage-capture
find /etc/nginx/sites-enabled/ -name '*black*' ! -name 'blackpage' -delete 2>/dev/null || true

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
    index index2.php index.php index.html;

    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    fastcgi_read_timeout 300;

    location / {
        try_files \$uri \$uri/ /index2.php?\$query_string;
    }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_read_timeout 300;
    }
}
EOF

ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage
nginx -t && systemctl reload nginx

echo "=== Tests ==="
echo -n "adoonline: "
curl -skI --max-time 15 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "adoonline body: "
curl -sk --max-time 15 https://127.0.0.1 -H "Host: adoonline.click" | wc -c
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== FIN ==="
