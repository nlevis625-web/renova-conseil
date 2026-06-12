<?php
header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Politique cookies — Renova Solaire</title>
  <link rel="stylesheet" href="../css/style.css">
</head>
<body>
  <header class="header">
    <div class="container header__inner">
      <a href="../index.php" class="logo">
        <span class="logo__mark">☀</span>
        <span class="logo__text">Renova <em>Solaire</em></span>
      </a>
    </div>
  </header>
  <main class="container legal-page">
    <a href="../index.php" class="back-link">← Retour à l'accueil</a>
    <h1>Politique cookies</h1>
    <p class="updated">Dernière mise à jour : juin <?php echo date('Y'); ?></p>

    <h2>Qu'est-ce qu'un cookie ?</h2>
    <p>
      Un cookie est un petit fichier texte déposé sur votre appareil lors de la visite
      d'un site web. Il permet de mémoriser vos préférences et d'améliorer votre expérience.
    </p>

    <h2>Cookies utilisés</h2>
    <ul>
      <li><strong>renova_cookies</strong> — mémorise votre acceptation de la bannière cookies (localStorage, durée : 12 mois)</li>
      <li><strong>Cookies analytiques</strong> — mesure d'audience anonymisée (si activés par l'hébergeur)</li>
    </ul>

    <h2>Gestion des cookies</h2>
    <p>
      Vous pouvez refuser ou supprimer les cookies via les paramètres de votre navigateur.
      La désactivation de certains cookies peut limiter certaines fonctionnalités du site.
    </p>

    <h2>Contact</h2>
    <p>Questions : contact@renova-conseil.com</p>
  </main>
  <footer class="footer">
    <div class="container footer__bottom">
      <p>© <?php echo date('Y'); ?> Renova Solaire · <a href="privacy.php">Confidentialité</a></p>
    </div>
  </footer>
</body>
</html>
