# Backup config Nginx production — renova-conseil.com ✅

Config PHP + HTTPS (certbot). Socket PHP : `/var/run/php/php-fpm.sock` ou `php8.3-fpm.sock`.

```nginx
server {
    listen 80;
    listen [::]:80;
    server_name renova-conseil.com www.renova-conseil.com;
    return 301 https://$host$request_uri;
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

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
    }
}
```

## sites-enabled — garder uniquement

- `renova-conseil.conf`

## Supprimer si présents

- `renovia-conseil.conf`
- `adoonline*`
- `default`
