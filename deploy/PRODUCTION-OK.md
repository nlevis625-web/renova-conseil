# Backup config Nginx production — renova-conseil.com

server {
    listen 80;
    listen [::]:80;
    server_name renova-conseil.com www.renova-conseil.com;
    root /var/www/renova-conseil;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;
    }
}

# SSL ajouté par certbot — ne pas dupliquer manuellement
