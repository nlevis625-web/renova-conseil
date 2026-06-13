#!/bin/bash
# UNIQUEMENT adoonline.click — restaurer comme avant
# Ne modifie PAS renova-conseil
set -e

BP="/var/www/blackpage"
PHP_SOCK="/var/run/php/php8.3-fpm.sock"
[ -S "$PHP_SOCK" ] || PHP_SOCK="/var/run/php/php-fpm.sock"

echo "=== Restauration fichiers originaux ==="
cd "$BP"

# Restaurer index.php depuis la plus ancienne sauvegarde (avant nos patches)
OLDEST=$(ls -t index.php.bak.* 2>/dev/null | tail -1)
if [ -n "$OLDEST" ] && [ -f "$OLDEST" ]; then
  cp -a "$OLDEST" index.php
  echo "index.php restaure depuis $OLDEST"
fi

# Restaurer index2.php si desactive
if [ -f index2.php.disabled ]; then
  mv index2.php.disabled index2.php
  echo "index2.php reactive"
fi
OLDEST2=$(ls -t index2.php.bak.* 2>/dev/null | tail -1)
if [ -n "$OLDEST2" ] && [ -f "$OLDEST2" ]; then
  cp -a "$OLDEST2" index2.php
  echo "index2.php restaure depuis $OLDEST2"
fi

# Supprimer nos modifications (html vide, user.ini)
rm -f index.html index.html.new index.html.petit.bak .user.ini

# Fichier principal = index.php (comme a l'origine sur ce serveur)
echo "=== Nginx adoonline seulement ==="
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

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \\.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_SOCK};
    }
}
EOF

# Activer UNIQUEMENT blackpage (ne pas toucher renova-conseil.conf)
rm -f /etc/nginx/sites-enabled/adoonline.conf
rm -f /etc/nginx/sites-enabled/blackpage-capture
ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage

systemctl restart php8.3-fpm 2>/dev/null || systemctl restart php*-fpm
nginx -t && systemctl reload nginx

echo "=== Test adoonline ==="
BODY=$(curl -sk --max-time 60 https://127.0.0.1/ -H "Host: adoonline.click" | wc -c)
echo "body: ${BODY} octets"
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
tail -3 /var/log/nginx/error.log 2>/dev/null | grep -i blackpage || tail -3 /var/log/nginx/error.log 2>/dev/null || true
echo "=== FIN adoonline ==="
