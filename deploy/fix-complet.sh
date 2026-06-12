#!/bin/bash
# Fix complet renova-conseil.com — port 80/443 + PHP + SSL
set -e

echo "=== 1. Stop conflits port 80 ==="
systemctl stop nginx apache2 2>/dev/null || true
sleep 2
for pid in $(ss -tlnp | grep ':80 ' | grep -oP 'pid=\K[0-9]+' | sort -u); do kill -9 "$pid" 2>/dev/null || true; done

echo "=== 2. Fichiers site ==="
mkdir -p /var/www/renova-conseil
cd /var/www/renova-conseil
if [ ! -f index.php ]; then
  git clone https://github.com/nlevis625-web/renova-conseil.git /tmp/renova-tmp
  cp -a /tmp/renova-tmp/. /var/www/renova-conseil/
  rm -rf /tmp/renova-tmp
fi

echo "=== 3. PHP + Nginx ==="
apt update -qq
apt install -y nginx php-fpm git certbot python3-certbot-nginx
PHP_SOCK=$(ls /var/run/php/*.sock | head -1)
echo "PHP: $PHP_SOCK"

rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/renovia*
rm -f /etc/nginx/sites-enabled/adoonline*
rm -f /etc/nginx/sites-enabled/pop3

cat > /etc/nginx/sites-available/renova-conseil.conf << EOF
server {
    listen 80;
    listen [::]:80;
    server_name renova-conseil.com www.renova-conseil.com;
    root /var/www/renova-conseil;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF

ln -sf /etc/nginx/sites-available/renova-conseil.conf /etc/nginx/sites-enabled/
nginx -t
systemctl enable nginx
systemctl restart nginx
systemctl restart php*-fpm 2>/dev/null || systemctl restart php8.3-fpm

echo "=== 4. Test HTTP ==="
curl -sI http://127.0.0.1 -H "Host: renova-conseil.com" | head -1

echo "=== 5. SSL ==="
if [ -f /etc/letsencrypt/live/renova-conseil.com/fullchain.pem ]; then
  certbot install --cert-name renova-conseil.com --nginx 2>/dev/null || \
  certbot --nginx -d renova-conseil.com -d www.renova-conseil.com \
    --non-interactive --agree-tos -m contact@renova-conseil.com --redirect
else
  certbot --nginx -d renova-conseil.com -d www.renova-conseil.com \
    --non-interactive --agree-tos -m contact@renova-conseil.com --redirect
fi

nginx -t && systemctl reload nginx

echo "=== 6. Tests finaux ==="
curl -sI http://127.0.0.1 -H "Host: renova-conseil.com" | head -1
curl -skI https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== FIN ==="
