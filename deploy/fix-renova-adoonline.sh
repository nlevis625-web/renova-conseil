#!/bin/bash
# Fix renova 502 + adoonline HTML complet (index2.php)
set -e

echo "=== 1. PHP-FPM (pour renova) ==="
apt update -qq
apt install -y php-fpm nginx

PHP_VER=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
PHP_INI="/etc/php/${PHP_VER}/fpm/php.ini"
sed -i 's/^memory_limit = .*/memory_limit = 1024M/' "$PHP_INI"

systemctl enable php${PHP_VER}-fpm nginx
systemctl restart php${PHP_VER}-fpm
sleep 2

PHP_SOCK=$(ls /var/run/php/php${PHP_VER}-fpm.sock 2>/dev/null || ls /var/run/php/*.sock | head -1)
echo "Socket PHP: $PHP_SOCK"

echo "=== 2. Nginx renova-conseil ==="
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
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/renova-conseil.conf /etc/nginx/sites-enabled/

echo "=== 3. Generer index.html complet pour adoonline ==="
BP="/var/www/blackpage"
cd "$BP"

# Sauvegarder le petit index.html rate
[ -f index.html ] && cp -a index.html index.html.petit.bak

# Config PHP temporaire pour capturer la page
cat > /etc/nginx/sites-available/blackpage << NGINXEOF
server {
    listen 8081;
    server_name localhost;
    root /var/www/blackpage;
    index index2.php index.php index.html;
    location / { try_files \$uri \$uri/ /index2.php?\$query_string; }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF

# Ajouter temporairement sur port 8081
grep -q "listen 8081" /etc/nginx/sites-enabled/blackpage-temp 2>/dev/null || \
  ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage-temp 2>/dev/null || true

# Remettre blackpage public en HTML (config finale)
cat > /etc/nginx/sites-available/blackpage << 'NGINXEOF'
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
NGINXEOF

# Config temp PHP sur 8081 pour capture
cat > /etc/nginx/sites-available/blackpage-capture << NGINXEOF
server {
    listen 127.0.0.1:8081;
    root /var/www/blackpage;
    index index2.php index.php;
    location / { try_files \$uri \$uri/ /index2.php?\$query_string; }
    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
NGINXEOF

ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage
ln -sf /etc/nginx/sites-available/blackpage-capture /etc/nginx/sites-enabled/blackpage-capture

nginx -t
systemctl reload nginx
sleep 1

# Capturer HTML rendu via PHP interne
curl -s --max-time 60 http://127.0.0.1:8081/ > "$BP/index.html" 2>/dev/null || true

# Si trop petit, essayer index.php direct CLI
SIZE=$(wc -c < "$BP/index.html" 2>/dev/null || echo 0)
if [ "$SIZE" -lt 5000 ]; then
  echo "Capture curl petite ($SIZE o), essai index2.php CLI..."
  timeout 90 php -d memory_limit=1024M index2.php > "$BP/index.html" 2>/dev/null || \
  timeout 90 php -d memory_limit=1024M index.php > "$BP/index.html" 2>/dev/null || true
fi

SIZE=$(wc -c < "$BP/index.html")
echo "index.html final: $SIZE octets"
chown www-data:www-data "$BP/index.html"

# Retirer config temporaire
rm -f /etc/nginx/sites-enabled/blackpage-capture
nginx -t && systemctl reload nginx

echo "=== 4. Tests ==="
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo -n "adoonline: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo "=== TERMINE ==="
