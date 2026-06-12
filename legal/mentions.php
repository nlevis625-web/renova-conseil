<?php
header('Content-Type: text/html; charset=UTF-8');
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Mentions légales — Renova Solaire</title>
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
    <h1>Mentions légales</h1>
    <p class="updated">Dernière mise à jour : juin <?php echo date('Y'); ?></p>

    <h2>Éditeur du site</h2>
    <p>
      <strong>Renova Solaire SAS</strong><br>
      Société par actions simplifiée au capital de 10 000 €<br>
      Siège social : 12 avenue des Énergies, 75008 Paris, France<br>
      RCS Paris 912 456 789 · SIRET 912 456 789 00012<br>
      TVA intracommunautaire : FR45912456789<br>
      Directeur de la publication : Marc Delacroix<br>
      Contact : contact@renova-conseil.com · +33 1 84 80 12 45
    </p>

    <h2>Hébergeur</h2>
    <p>
      Le site est hébergé par DigitalOcean LLC, 101 Avenue of the Americas, New York, NY 10013, États-Unis.<br>
      Pour toute question relative à l'hébergement, contactez contact@renova-conseil.com.
    </p>

    <h2>Activité</h2>
    <p>
      Renova Solaire est un service d'information et de mise en relation dans le domaine
      des panneaux solaires et de l'autoconsommation. Nous ne réalisons pas directement de travaux.
      Les montants d'aides et estimations affichés sont indicatifs et non contractuels.
    </p>

    <h2>Propriété intellectuelle</h2>
    <p>
      L'ensemble du contenu de ce site (textes, graphismes, logo, structure) est protégé
      par le droit d'auteur. Toute reproduction sans autorisation écrite est interdite.
    </p>

    <h2>Limitation de responsabilité</h2>
    <p>
      Renova Solaire s'efforce de fournir des informations exactes et à jour. Toutefois,
      nous ne garantissons pas l'exhaustivité ou l'absence d'erreur. Les dispositifs d'aides
      publics évoluent régulièrement — vérifiez toujours auprès des autorités compétentes.
    </p>
  </main>
  <footer class="footer">
    <div class="container footer__bottom">
      <p>© <?php echo date('Y'); ?> Renova Solaire · <a href="privacy.php">Confidentialité</a> · <a href="terms.php">CGU</a></p>
    </div>
  </footer>
</body>
</html>
