#!/bin/bash
# Supprime le doublon adoonline — garde blackpage + renova separes
set -e

echo "=== Configs actives ==="
ls -la /etc/nginx/sites-enabled/

echo "=== Supprimer doublon adoonline.conf ==="
rm -f /etc/nginx/sites-enabled/adoonline.conf

echo "=== Verifier blackpage ==="
test -f /etc/nginx/sites-enabled/blackpage || \
  ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage

PHP_SOCK=$(ls /var/run/php/*.sock | head -1)

# S'assurer que blackpage a la bonne config
if [ -f /etc/nginx/sites-available/blackpage ]; then
  grep -q "root /var/www/blackpage" /etc/nginx/sites-available/blackpage || \
  cat > /etc/nginx/sites-available/blackpage << NGINXEOF
server {
    listen 80;
    listen [::]:80;
    server_name adoonline.click www.adoonline.click;
    root /var/www/blackpage;
    index index.php index.html;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF
fi

echo "=== Memoire PHP blackpage ==="
echo "memory_limit = 512M" > /var/www/blackpage/.user.ini

echo "=== SSL blackpage ==="
certbot install --cert-name adoonline.click 2>/dev/null || true

nginx -t
systemctl reload nginx

echo "=== Tests HTTPS ==="
echo -n "renova: "
curl -skI https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo -n "adoonline: "
curl -skI https://127.0.0.1 -H "Host: adoonline.click" | head -1

echo "=== TERMINE ==="
