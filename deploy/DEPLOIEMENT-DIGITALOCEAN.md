# Déployer renovia-conseil.com sur DigitalOcean

Domaine : **renovia-conseil.com** (Spaceship)  
DNS : **Cloudflare**  
Hébergement : **DigitalOcean**

---

## Option A — Droplet + Nginx (recommandé, ~6 $/mois)

### 1. Créer le Droplet

1. [cloud.digitalocean.com](https://cloud.digitalocean.com) → **Create** → **Droplets**
2. **Ubuntu 24.04**
3. Plan **Basic** 1 GB (~6 $/mois)
4. Région : **Frankfurt** (proche FR/BE/LU/CH)
5. Auth : mot de passe ou clé SSH
6. Nom : `renovia-conseil`
7. Notez l’**IP publique** (ex. `164.92.xxx.xxx`)

### 2. Envoyer les fichiers du site

**Depuis Windows (PowerShell)** — remplacez `IP` et le chemin de votre clé :

```powershell
scp -r "C:\Users\nlevi\Projects\renovia-conseil\index.html" `
        "C:\Users\nlevi\Projects\renovia-conseil\css" `
        "C:\Users\nlevi\Projects\renovia-conseil\js" `
        "C:\Users\nlevi\Projects\renovia-conseil\legal" `
        root@IP:/var/www/renovia-conseil/
```

Ou avec **WinSCP** / **FileZilla** (SFTP) :
- Hôte : IP du Droplet
- Dossier distant : `/var/www/renovia-conseil/`

### 3. Installer Nginx sur le Droplet

Connectez-vous en SSH :

```bash
ssh root@IP
```

Puis :

```bash
apt update && apt install -y nginx certbot python3-certbot-nginx
mkdir -p /var/www/renovia-conseil
```

Copiez la config nginx (contenu de `deploy/nginx-renovia-conseil.conf`) :

```bash
nano /etc/nginx/sites-available/renovia-conseil.conf
```

Activez le site :

```bash
ln -sf /etc/nginx/sites-available/renovia-conseil.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx
```

Certificat HTTPS :

```bash
certbot --nginx -d renovia-conseil.com -d www.renovia-conseil.com
```

### 4. DNS Cloudflare

Dans **Cloudflare** → `renovia-conseil.com` → **DNS** :

| Type | Nom | Contenu | Proxy |
|------|-----|---------|-------|
| **A** | `@` | `IP_DU_DROPLET` | Proxied (nuage orange) |
| **CNAME** | `www` | `renovia-conseil.com` | Proxied |

**SSL/TLS** Cloudflare → mode **Full (strict)** (après certbot sur le Droplet).

---

## Option B — App Platform (sans gérer un serveur)

1. Poussez le projet sur **GitHub**
2. DigitalOcean → **Apps** → **Create App** → GitHub → repo `renovia-conseil`
3. Type : **Static Site**, output dir `/`
4. **Settings** → **Domains** → ajoutez `renovia-conseil.com` et `www`
5. DigitalOcean affiche un **CNAME** — ajoutez-le dans Cloudflare :

| Type | Nom | Contenu |
|------|-----|---------|
| **CNAME** | `@` | `votre-app.ondigitalocean.app` |
| **CNAME** | `www` | `votre-app.ondigitalocean.app` |

*(Cloudflare gère le CNAME sur `@` via flattening.)*

---

## Vérification

- https://renovia-conseil.com
- https://www.renovia-conseil.com
- Pages légales : `/legal/privacy.html`

Propagation DNS : 15 min – 2 h.
