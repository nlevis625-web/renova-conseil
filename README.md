# Renovia Conseil — Safepage

Site statique de rénovation énergétique (FR · BE · LU · CH).

## Structure

```
renovia-conseil/
├── index.html          # Page principale
├── css/style.css       # Styles
├── js/main.js          # Simulateur + formulaire
└── legal/              # Pages légales (RGPD, CGU, cookies)
```

## Prévisualisation locale

```powershell
cd C:\Users\nlevi\Projects\renovia-conseil
python -m http.server 8080
```

Ouvrir http://localhost:8080

## Hébergement — DigitalOcean + Cloudflare

Guide complet : **`deploy/DEPLOIEMENT-DIGITALOCEAN.md`**

Résumé :
1. Droplet Ubuntu → Nginx → `/var/www/renovia-conseil/`
2. Cloudflare DNS : **A** `@` → IP du Droplet
3. `certbot --nginx -d renovia-conseil.com -d www.renovia-conseil.com`

## Domaine

- **renovia-conseil.com** (actif)

## Marque

**Renovia Conseil** — cabinet indépendant en rénovation énergétique.
Identité visuelle : vert forêt (#166534), typographie DM Sans + Instrument Serif.

## Notes

- Les formulaires affichent une confirmation côté client (pas de backend).
- Pour recevoir les leads, connectez un service (Formspree, Netlify Forms, webhook).
- Les montants d'aides sont indicatifs — à adapter selon vos campagnes.
