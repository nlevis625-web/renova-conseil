#!/bin/bash
# adoonline.click — repasser en HTML statique (sans PHP)
set -e

BP="/var/www/blackpage"
echo "=== Fichiers blackpage ==="
ls -la "$BP/" 2>/dev/null || { echo "Dossier $BP absent"; exit 1; }

cd "$BP"

echo "=== Creer / restaurer index.html ==="
if [ -f index.html ] && [ -s index.html ]; then
  echo "index.html deja present"
elif [ -f index.html.bak ]; then
  cp index.html.bak index.html
  echo "index.html restaure depuis backup"
elif [ -f index.htm ]; then
  cp index.htm index.html
elif [ -f index.php ]; then
  echo "Generation index.html depuis index.php (une fois)..."
  cp -a index.php "index.php.bak.$(date +%s)"
  timeout 60 php -d memory_limit=1024M -d max_execution_time=120 index.php > index.html 2>/dev/null || true
  if [ ! -s index.html ]; then
    echo "Generation PHP echouee — recherche autre HTML..."
    find "$BP" -maxdepth 2 -name "*.html" -size +1k | head -1 | xargs -I{} cp {} index.html
  fi
fi

if [ ! -f index.html ] || [ ! -s index.html ]; then
  echo "ERREUR: pas de index.html utilisable. Fichiers:"
  ls -la "$BP/"
  exit 1
fi

echo "index.html OK ($(wc -c < index.html) octets)"

echo "=== Nginx HTML uniquement (pas de PHP) ==="
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

    location / {
        try_files $uri $uri/ /index.html;
    }
}
NGINXEOF

rm -f /etc/nginx/sites-enabled/adoonline.conf
ln -sf /etc/nginx/sites-available/blackpage /etc/nginx/sites-enabled/blackpage

nginx -t
systemctl reload nginx

echo "=== SSL ==="
certbot install --cert-name adoonline.click 2>/dev/null || true
nginx -t && systemctl reload nginx

echo "=== Tests ==="
echo -n "adoonline HTTP: "
curl -sI --max-time 10 http://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "adoonline HTTPS: "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
echo -n "renova (inchange): "
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1

echo "=== TERMINE — adoonline en HTML statique ==="
