#!/bin/bash
# Fix rapide adoonline.click — HTML statique (renova intact)
set -e

BP="/var/www/blackpage"
PHP_SOCK=$(ls /var/run/php/php*-fpm.sock 2>/dev/null || ls /var/run/php/*.sock | head -1)

echo "Socket: $PHP_SOCK"
systemctl restart php*-fpm 2>/dev/null || systemctl restart php8.3-fpm

cd "$BP"

# Capture HTML via PHP interne (headers corrects)
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
nginx -t && systemctl reload nginx
sleep 1

curl -s --max-time 90 http://127.0.0.1:8081/ > "${BP}/index.html" || true
SIZE=$(wc -c < "${BP}/index.html")
echo "index.html: ${SIZE} octets"

if [ "$SIZE" -lt 5000 ]; then
  curl -s --max-time 90 -H "Host: adoonline.click" http://127.0.0.1:8081/index.php > "${BP}/index.html" || true
  SIZE=$(wc -c < "${BP}/index.html")
  echo "retry index.php: ${SIZE} octets"
fi

chown www-data:www-data "${BP}/index.html"
rm -f /etc/nginx/sites-enabled/blackpage-capture

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
rm -f /etc/nginx/sites-enabled/adoonline.conf
nginx -t && systemctl reload nginx

echo -n "adoonline: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== OK ==="
