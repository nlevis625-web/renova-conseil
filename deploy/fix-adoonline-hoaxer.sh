#!/bin/bash
# Fix Hoaxer duplicate class — adoonline.click
set -e

BP="/var/www/blackpage"
PHP_SOCK="/var/run/php/php8.3-fpm.sock"
[ -S "$PHP_SOCK" ] || PHP_SOCK="/var/run/php/php-fpm.sock"

cd "$BP"
cp -a index2.php "index2.php.bak.$(date +%s)" 2>/dev/null || true
cp -a index.php "index.php.bak.$(date +%s)" 2>/dev/null || true

echo "=== Patch class Hoaxer (evite double declaration) ==="
for f in index.php index2.php; do
  [ -f "$f" ] || continue
  if grep -q 'class Hoaxer' "$f"; then
    sed -i 's/class Hoaxer/if (!class_exists("Hoaxer")) class Hoaxer/' "$f"
    echo "patche: $f"
  fi
done

# require -> require_once pour les includes locaux
for f in index.php index2.php; do
  [ -f "$f" ] || continue
  sed -i "s/require '/require_once '/g; s/require \"/require_once \"/g" "$f" 2>/dev/null || true
  sed -i "s/include '/include_once '/g; s/include \"/include_once \"/g" "$f" 2>/dev/null || true
done

systemctl restart php8.3-fpm

echo "=== Test fichiers PHP ==="
B1=$(curl -sk --max-time 30 https://127.0.0.1/index.php -H "Host: adoonline.click" | wc -c)
B2=$(curl -sk --max-time 30 https://127.0.0.1/index2.php -H "Host: adoonline.click" | wc -c)
echo "index.php: ${B1} octets | index2.php: ${B2} octets"

if [ "$B1" -ge "$B2" ] && [ "$B1" -gt 1000 ]; then
  INDEX="index.php"
else
  INDEX="index2.php"
fi
echo "Index nginx: $INDEX"

# Nettoyer doublons nginx
for f in /etc/nginx/sites-enabled/*; do
  base=$(basename "$f")
  case "$base" in blackpage|renova-conseil.conf) ;; *) rm -f "$f" ;; esac
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
    index ${INDEX};

    ssl_certificate /etc/letsencrypt/live/adoonline.click/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/adoonline.click/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        try_files \$uri /${INDEX}?\$query_string;
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

echo "=== Resultat ==="
BODY=$(curl -sk --max-time 30 https://127.0.0.1/ -H "Host: adoonline.click" | wc -c)
echo "adoonline body: ${BODY} octets"
curl -sk --max-time 30 https://127.0.0.1/ -H "Host: adoonline.click" | head -2
echo -n "adoonline: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "renova: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== FIN ==="
