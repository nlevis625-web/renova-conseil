#!/bin/bash
set -euo pipefail

# À lancer sur un Droplet Ubuntu 22.04/24.04 (root ou sudo)
# Usage: bash setup-droplet.sh

apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

mkdir -p /var/www/renovia-conseil
chown -R www-data:www-data /var/www/renovia-conseil

cp deploy/nginx-renovia-conseil.conf /etc/nginx/sites-available/renovia-conseil.conf
ln -sf /etc/nginx/sites-available/renovia-conseil.conf /etc/nginx/sites-enabled/renovia-conseil.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl reload nginx
systemctl enable nginx

echo ""
echo "✓ Nginx installé. Copiez les fichiers du site dans /var/www/renovia-conseil/"
echo "  Puis lancez: certbot --nginx -d renovia-conseil.com -d www.renovia-conseil.com"
