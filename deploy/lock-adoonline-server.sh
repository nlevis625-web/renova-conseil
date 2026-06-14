#!/bin/bash
# Verrouiller adoonline.click sur le serveur — une fois dans console DigitalOcean
set -e

BP="/var/www/blackpage"

echo "=== Verrouillage adoonline.click ==="

# Supprimer PHP (ne doit plus servir)
rm -f "$BP/index.php" "$BP/index2.php" "$BP/index2.php.disabled"
rm -f "$BP/index.html.new" "$BP/.user.ini"

# Proprietaire puis lecture seule (chown avant chattr +i)
chown -R www-data:www-data "$BP"
chmod 755 "$BP"

for f in index.html loader.js app.bundle.js styles.css bsod-qr.svg; do
  [ -f "$BP/$f" ] || continue
  chmod 444 "$BP/$f"
  chattr +i "$BP/$f" 2>/dev/null || true
  echo "verrouille: $f"
done

# Nginx adoonline — lecture seule
if [ -f /etc/nginx/sites-available/blackpage ]; then
  chmod 444 /etc/nginx/sites-available/blackpage
  chattr +i /etc/nginx/sites-available/blackpage 2>/dev/null || true
fi

# Supprimer configs doublons
rm -f /etc/nginx/sites-enabled/adoonline.conf
rm -f /etc/nginx/sites-enabled/blackpage-capture

nginx -t && systemctl reload nginx

echo "=== OK — adoonline.click verrouille ==="
ls -la "$BP/"
