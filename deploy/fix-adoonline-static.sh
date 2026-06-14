#!/bin/bash
# adoonline.click — site statique complet (index inline + assets)
# Ne touche PAS renova-conseil.com
set -e

BP="/var/www/blackpage"
mkdir -p "$BP"
cd "$BP"

echo "=== 1. Cle SSH PC ==="
mkdir -p ~/.ssh
grep -qF "IGVtJUHLpthbNUakK2TgyVtt6C" ~/.ssh/authorized_keys 2>/dev/null || \
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVtJUHLpthbNUakK2TgyVtt6C/1YP92Wr3aCZ6kn0y2 nlevi@WIN-NQ4H5FAHO3S" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

echo "=== 2. Nettoyage ==="
rm -f index.php index2.php index2.php.disabled .user.ini
rm -f index.html.new index.html.petit.bak

echo "=== 3. Telechargement site complet ==="
curl -fsSL "https://raw.githubusercontent.com/nlevis625-web/renova-conseil/main/deploy/adoonline-bundle.tar.gz" -o /tmp/ado.tar.gz
tar -xzf /tmp/ado.tar.gz -C "$BP"
rm -f /tmp/ado.tar.gz
chown -R www-data:www-data "$BP"

echo "=== 4. Nginx adoonline ==="
for f in /etc/nginx/sites-enabled/*; do
  base=$(basename "$f")
  case "$base" in blackpage|renova-conseil.conf) ;; *) rm -f "$f" ;; esac
done
rm -f /etc/nginx/sites-enabled/adoonline.conf /etc/nginx/sites-enabled/blackpage-capture

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
nginx -t && systemctl reload nginx

echo "=== 5. Tests ==="
wc -c "$BP/index.html" "$BP/loader.js" "$BP/app.bundle.js" 2>/dev/null || true
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== OK adoonline.click ==="
