#!/bin/bash
# Fix rapide adoonline.click v2 — HTML statique
set -e

BP="/var/www/blackpage"

# UN seul socket PHP (pas deux lignes)
if [ -S /var/run/php/php8.3-fpm.sock ]; then
  PHP_SOCK="/var/run/php/php8.3-fpm.sock"
elif [ -S /var/run/php/php-fpm.sock ]; then
  PHP_SOCK="/var/run/php/php-fpm.sock"
else
  PHP_SOCK=$(find /var/run/php -name "*.sock" | head -1)
fi
echo "Socket: $PHP_SOCK"

systemctl restart php8.3-fpm 2>/dev/null || systemctl restart php*-fpm

# Nettoyer doublons nginx adoonline
rm -f /etc/nginx/sites-enabled/adoonline.conf
rm -f /etc/nginx/sites-enabled/blackpage-capture
ls /etc/nginx/sites-enabled/ | grep -i black | while read f; do
  [ "$f" != "blackpage" ] && rm -f "/etc/nginx/sites-enabled/$f"
done

cd "$BP"

# Capture HTML via PHP interne
cat > /etc/nginx/sites-available/blackpage-capture << EOF
server {
    listen 127.0.0.1:8081;
    root ${BP};
    index index2.php index.php;
    location / { try_files \$uri /index2.php; }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
        fastcgi_param HTTP_HOST adoonline.click;
        fastcgi_param REQUEST_URI /;
        fastcgi_param HTTPS on;
    }
}
EOF

ln -sf /etc/nginx/sites-available/blackpage-capture /etc/nginx/sites-enabled/blackpage-capture
nginx -t
systemctl reload nginx
sleep 2

curl -s --max-time 90 http://127.0.0.1:8081/ > "${BP}/index.html.new"
SIZE=$(wc -c < "${BP}/index.html.new")
echo "capture index2: ${SIZE} octets"

if [ "$SIZE" -lt 5000 ]; then
  curl -s --max-time 90 http://127.0.0.1:8081/index.php > "${BP}/index.html.new"
  SIZE=$(wc -c < "${BP}/index.html.new")
  echo "capture index.php: ${SIZE} octets"
fi

if [ "$SIZE" -gt 5000 ]; then
  mv "${BP}/index.html.new" "${BP}/index.html"
  chown www-data:www-data "${BP}/index.html"
  echo "index.html OK"
else
  echo "ATTENTION: capture petite (${SIZE}o) — garde ancien index.html si present"
  rm -f "${BP}/index.html.new"
fi

rm -f /etc/nginx/sites-enabled/blackpage-capture

# UNE seule config blackpage
cat > /etc/nginx/sites-available/blackpage << 'EOF'
server {
    listen 80;
    listen [::]:80;
    server_name adoonline.click www.adoonline.click;
    return 301 https://$host$request_uri;
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name adoonline.click www.adoonline.click;
    root /var/www/blackpage;
    index index.html;
    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;
    location / { try_files $uri $uri/ /index.html; }
}
EOF

ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage
nginx -t
systemctl reload nginx

echo "=== Tests ==="
wc -c "${BP}/index.html" 2>/dev/null || echo "pas d index.html"
echo -n "adoonline: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== FIN ==="
