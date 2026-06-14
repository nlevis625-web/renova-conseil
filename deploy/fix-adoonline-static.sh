#!/bin/bash
# adoonline.click — restauration complete (JS + vrais MP3 originaux)
# Ne touche PAS renova-conseil.com
set -e

BP="/var/www/blackpage"
mkdir -p "$BP"

echo "=== 1. Cle SSH PC ==="
mkdir -p ~/.ssh
grep -qF "IGVtJUHLpthbNUakK2TgyVtt6C" ~/.ssh/authorized_keys 2>/dev/null || \
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGVtJUHLpthbNUakK2TgyVtt6C/1YP92Wr3aCZ6kn0y2 nlevi@WIN-NQ4H5FAHO3S" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys

echo "=== 2. Deverrouiller fichiers (chattr) ==="
for f in "$BP"/*; do
  chattr -i "$f" 2>/dev/null || true
done

echo "=== 3. Nettoyage PHP ==="
rm -f "$BP/index.php" "$BP/index2.php" "$BP/index2.php.disabled" "$BP/.user.ini"
rm -f "$BP/index.html.new" "$BP/index.html.petit.bak"

echo "=== 4. Telechargement site complet + audios originaux ==="
curl -fsSL "https://raw.githubusercontent.com/nlevis625-web/renova-conseil/main/deploy/adoonline-bundle.tar.gz" -o /tmp/ado.tar.gz
tar -xzf /tmp/ado.tar.gz -C "$BP"
rm -f /tmp/ado.tar.gz
chown -R www-data:www-data "$BP"
chmod 444 "$BP/script-audio.mp3" "$BP/script-audio-2.mp3" 2>/dev/null || true

echo "=== 5. Nginx adoonline ==="
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

echo "=== 6. Tests ==="
wc -c "$BP/index.html" "$BP/loader.js" "$BP/app.bundle.js" "$BP/script-audio.mp3" "$BP/script-audio-2.mp3"
A1=$(wc -c < "$BP/script-audio.mp3")
A2=$(wc -c < "$BP/script-audio-2.mp3")
if [ "$A1" -lt 200000 ] || [ "$A2" -lt 5000 ]; then
  echo "ERREUR: audios incorrects (attendu ~301101 et ~8624)"
  exit 1
fi
curl -skI --max-time 10 https://127.0.0.1/script-audio.mp3 -H "Host: adoonline.click" | head -2
curl -skI --max-time 10 https://127.0.0.1/script-audio-2.mp3 -H "Host: adoonline.click" | head -2
curl -skI --max-time 10 https://127.0.0.1 -H "Host: adoonline.click" | head -1
curl -skI --max-time 10 https://127.0.0.1 -H "Host: renova-conseil.com" | head -1
echo "=== OK ADOONLINE COMPLET ==="
