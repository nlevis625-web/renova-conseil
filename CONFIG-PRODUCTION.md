# Renova Solaire — Production OK ✅ (12 juin 2026)

**Statut : site en ligne et fonctionnel (HTTP + HTTPS)**

## Identité

| Élément | Valeur |
|---------|--------|
| **Domaine** | https://renova-conseil.com |
| **Marque** | Renova Solaire (panneaux solaires) |
| **E-mail** | contact@renova-conseil.com |
| **Google Ads** | https://renova-conseil.com |

> **Attention :** c'est **renova** (sans « i »), pas renovia.

## Hébergement

| Élément | Valeur |
|---------|--------|
| **IP Droplet** | 159.89.50.166 |
| **Dossier serveur** | `/var/www/renova-conseil/` |
| **DNS** | Cloudflare — A `@` → `159.89.50.166`, SSL **Full (strict)** |
| **Stack** | Nginx + PHP-FPM 8.3 + Let's Encrypt |

## Code

| Élément | Valeur |
|---------|--------|
| **Fichier principal** | `index.php` |
| **GitHub** | https://github.com/nlevis625-web/renova-conseil.git |
| **Local PC** | `C:\Users\nlevi\Projects\renovia-conseil` |

## Mises à jour

**PC (Git Bash) :**
```bash
cd /c/Users/nlevi/Projects/renovia-conseil
git add .
git commit -m "Mise à jour safepage"
git push
```

**Serveur (console DigitalOcean) :**
```bash
cd /var/www/renova-conseil && git pull
```

## Problèmes résolus

1. Dossier `/var/www/renova-conseil/` absent → `git clone` dans le bon chemin
2. Repo GitHub renommé → `renova-conseil` (plus `renovia-conseil`)
3. HTTP OK mais HTTPS 404 → certbot + config SSL corrigée
4. Conflits nginx (`renovia-conseil`, `adoonline`) → supprimés de `sites-enabled`

## Vérification rapide

```bash
curl -Ik https://127.0.0.1 -H "Host: renova-conseil.com"
# Attendu : HTTP/1.1 200 OK
```
