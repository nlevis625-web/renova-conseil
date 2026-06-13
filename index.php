<?php
header('Content-Type: text/html; charset=UTF-8');

$formSuccess = false;
$formError = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['contact_form'])) {
  $name = trim($_POST['name'] ?? '');
  $email = trim($_POST['email'] ?? '');
  $phone = trim($_POST['phone'] ?? '');
  $contactCountry = trim($_POST['contactCountry'] ?? '');
  $message = trim($_POST['message'] ?? '');
  $consent = isset($_POST['consent']);

  if ($name === '' || $email === '' || $phone === '' || $contactCountry === '' || $message === '' || !$consent) {
    $formError = 'Veuillez remplir tous les champs obligatoires.';
  } elseif (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    $formError = 'Adresse e-mail invalide.';
  } else {
    $storageDir = __DIR__ . '/storage';
    if (!is_dir($storageDir)) {
      mkdir($storageDir, 0750, true);
    }
    $line = implode(';', [
      date('c'),
      $name,
      $email,
      $phone,
      $contactCountry,
      str_replace(["\r", "\n", ';'], ' ', $message),
      $_SERVER['REMOTE_ADDR'] ?? '',
    ]) . PHP_EOL;
    file_put_contents($storageDir . '/leads.csv', $line, FILE_APPEND | LOCK_EX);
    $formSuccess = true;
  }
}
?>
<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="Renova Solaire — Panneaux solaires, autoconsommation et aides publiques en France, Belgique, Luxembourg et Suisse. Devis gratuit sous 24 h.">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="https://renova-conseil.com/">
  <meta property="og:title" content="Renova Solaire — Panneaux solaires & autoconsommation">
  <meta property="og:description" content="Estimez vos aides solaires et demandez un devis gratuit. FR · BE · LU · CH.">
  <meta property="og:url" content="https://renova-conseil.com/">
  <meta property="og:type" content="website">
  <meta property="og:locale" content="fr_FR">
  <title>Renova Solaire — Panneaux solaires & autoconsommation | Devis gratuit</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=Instrument+Serif:ital@0;1&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="css/style.css">
  <link rel="icon" href="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><rect fill='%23ca8a04' width='100' height='100' rx='20'/><text y='.9em' x='50%' text-anchor='middle' font-size='60' fill='white'>☀</text></svg>">
</head>
<body>
  <header class="header">
    <div class="container header__inner">
      <a href="index.php" class="logo">
        <span class="logo__mark">☀</span>
        <span class="logo__text">Renova <em>Solaire</em></span>
      </a>
      <nav class="nav" id="nav">
        <a href="#solutions">Solutions</a>
        <a href="#aides">Aides</a>
        <a href="#simulateur">Simulateur</a>
        <a href="#pays">Votre pays</a>
        <a href="#contact" class="nav__cta">Devis gratuit</a>
      </nav>
      <button class="menu-toggle" id="menuToggle" aria-label="Menu">
        <span></span><span></span><span></span>
      </button>
    </div>
  </header>

  <main>
    <section class="hero">
      <div class="container hero__grid">
        <div class="hero__content">
          <span class="badge">Panneaux solaires · FR · BE · LU · CH</span>
          <h1>Panneaux solaires : réduisez votre facture jusqu'à 70&nbsp;%</h1>
          <p class="hero__lead">
            Devis gratuit sous 24 h. Renova Solaire vous accompagne pour l'autoconsommation,
            la revente du surplus et les batteries — avec estimation des aides dans votre pays.
          </p>
          <div class="hero__actions">
            <a href="#simulateur" class="btn btn--primary">Estimer mes aides solaires</a>
            <a href="#contact" class="btn btn--ghost">Demander un devis</a>
          </div>
          <ul class="trust-list">
            <li>Étude gratuite et sans engagement</li>
            <li>Installateurs certifiés RGE / QualiPV</li>
            <li>Aides <?php echo date('Y'); ?> : prime autoconsommation, CEE, régionales</li>
          </ul>
        </div>
        <div class="hero__card">
          <div class="stat-card">
            <span class="stat-card__value">−70&nbsp;%</span>
            <span class="stat-card__label">sur votre facture d'électricité en autoconsommation</span>
          </div>
          <div class="stat-card stat-card--alt">
            <span class="stat-card__value">8–12 ans</span>
            <span class="stat-card__label">retour sur investissement moyen d'une installation résidentielle</span>
          </div>
        </div>
      </div>
    </section>

    <section class="section" id="solutions">
      <div class="container">
        <div class="section__head">
          <h2>Solutions photovoltaïques</h2>
          <p>Des installations adaptées à votre toiture, votre consommation et votre budget.</p>
        </div>
        <div class="cards">
          <article class="card">
            <div class="card__icon">☀</div>
            <h3>Autoconsommation</h3>
            <p>Consommez directement l'électricité produite par vos panneaux et réduisez votre facture EDF/Engie.</p>
            <ul>
              <li>3 à 12 kWc selon besoin</li>
              <li>Prime à l'autoconsommation</li>
              <li>Monitoring en temps réel</li>
            </ul>
          </article>
          <article class="card">
            <div class="card__icon">⚡</div>
            <h3>Revente du surplus</h3>
            <p>Revendez l'électricité non consommée au réseau et rentabilisez votre installation.</p>
            <ul>
              <li>Contrat EDF OA ou équivalent</li>
              <li>Tarif d'achat garanti</li>
              <li>Cumulable avec autoconsommation</li>
            </ul>
          </article>
          <article class="card">
            <div class="card__icon">🔋</div>
            <h3>Batterie de stockage</h3>
            <p>Stockez votre surplus solaire pour l'utiliser le soir et maximiser votre autonomie.</p>
            <ul>
              <li>Réduction pic de consommation</li>
              <li>Aides CEE possibles</li>
              <li>Indépendance énergétique</li>
            </ul>
          </article>
        </div>
      </div>
    </section>

    <section class="section section--muted" id="aides">
      <div class="container">
        <div class="section__head">
          <h2>Aides panneaux solaires par pays</h2>
          <p>Primes et dispositifs pour financer votre installation photovoltaïque.</p>
        </div>
        <div class="aides-grid" id="pays">
          <article class="aide-card" data-country="fr">
            <h3>🇫🇷 France</h3>
            <ul>
              <li><strong>Prime autoconsommation</strong> — jusqu'à 2 340 €</li>
              <li><strong>TVA 10&nbsp;%</strong> sur installation PV</li>
              <li><strong>CEE</strong> — prime énergie</li>
              <li><strong>Revente EDF OA</strong> — tarif garanti 20 ans</li>
            </ul>
          </article>
          <article class="aide-card" data-country="be">
            <h3>🇧🇪 Belgique</h3>
            <ul>
              <li><strong>Primes Région wallonne</strong> — photovoltaïque</li>
              <li><strong>Primes Bruxelles</strong> — certificats verts</li>
              <li><strong>Comwatt / Flandre</strong> selon région</li>
              <li><strong>Crédit d'impôt</strong> fédéral</li>
            </ul>
          </article>
          <article class="aide-card" data-country="lu">
            <h3>🇱🇺 Luxembourg</h3>
            <ul>
              <li><strong>Klimabonus</strong> — prime PV</li>
              <li><strong>Subvention autoconsommation</strong></li>
              <li><strong>TVA réduite</strong> 8 %</li>
              <li><strong>Guichet.lu</strong> — démarches en ligne</li>
            </ul>
          </article>
          <article class="aide-card" data-country="ch">
            <h3>🇨🇭 Suisse</h3>
            <ul>
              <li><strong>Subventions cantonales</strong> (VD, GE, BE…)</li>
              <li><strong>Rétribution injection</strong> réseau</li>
              <li><strong>Pro Energie</strong> selon canton</li>
              <li><strong>Exonérations fiscales</strong> locales</li>
            </ul>
          </article>
        </div>
      </div>
    </section>

    <section class="section" id="simulateur">
      <div class="container">
        <div class="simulator">
          <div class="simulator__info">
            <h2>Simulateur d'aides solaires</h2>
            <p>Estimation indicative pour une installation photovoltaïque. Un conseiller confirmera l'éligibilité exacte.</p>
          </div>
          <form class="simulator__form" id="simulatorForm">
            <div class="form-row">
              <label for="country">Pays</label>
              <select id="country" name="country" required>
                <option value="">Sélectionnez</option>
                <option value="fr">France</option>
                <option value="be">Belgique</option>
                <option value="lu">Luxembourg</option>
                <option value="ch">Suisse</option>
              </select>
            </div>
            <div class="form-row">
              <label for="project">Type d'installation</label>
              <select id="project" name="project" required>
                <option value="">Sélectionnez</option>
                <option value="solaire">Panneaux solaires (autoconsommation)</option>
                <option value="solaire-batterie">Panneaux + batterie</option>
                <option value="solaire-revente">Revente totale au réseau</option>
              </select>
            </div>
            <div class="form-row">
              <label for="income">Revenus du foyer (estimation)</label>
              <select id="income" name="income" required>
                <option value="">Sélectionnez</option>
                <option value="modest">Modestes</option>
                <option value="intermediate">Intermédiaires</option>
                <option value="high">Supérieurs</option>
              </select>
            </div>
            <div class="form-row">
              <label for="surface">Puissance souhaitée (kWc)</label>
              <input type="number" id="surface" name="surface" min="3" max="36" placeholder="Ex : 6" required>
            </div>
            <button type="submit" class="btn btn--primary btn--full">Calculer mon estimation</button>
          </form>
          <div class="simulator__result" id="simulatorResult" hidden>
            <h3>Estimation indicative</h3>
            <p class="result__amount" id="resultAmount">—</p>
            <p class="result__detail" id="resultDetail"></p>
            <a href="#contact" class="btn btn--primary">Confirmer avec un conseiller</a>
          </div>
        </div>
      </div>
    </section>

    <section class="section section--dark">
      <div class="container steps">
        <h2>Votre projet solaire en 3 étapes</h2>
        <ol class="steps__list">
          <li>
            <span class="steps__num">1</span>
            <div>
              <strong>Étude de faisabilité</strong>
              <p>Analyse de votre toiture, orientation et consommation électrique. Gratuit et sans engagement.</p>
            </div>
          </li>
          <li>
            <span class="steps__num">2</span>
            <div>
              <strong>Devis personnalisé</strong>
              <p>Un conseiller calcule les aides, la puissance optimale et le retour sur investissement.</p>
            </div>
          </li>
          <li>
            <span class="steps__num">3</span>
            <div>
              <strong>Installation certifiée</strong>
              <p>Mise en relation avec un installateur QualiPV / RGE près de chez vous.</p>
            </div>
          </li>
        </ol>
      </div>
    </section>

    <section class="section" id="contact">
      <div class="container">
        <div class="contact-grid">
          <div>
            <h2>Demandez votre devis solaire gratuit</h2>
            <p>Décrivez votre projet photovoltaïque. Un conseiller Renova Solaire vous rappelle sous 24 h ouvrées.</p>
            <div class="contact-info">
              <p><strong>Renova Solaire</strong></p>
              <p>12 avenue des Énergies<br>75008 Paris, France</p>
              <p>contact@renova-conseil.com</p>
              <p>Lun–Ven · 9h–18h (CET)</p>
            </div>
          </div>
          <form class="contact-form" id="contactForm" method="post" action="index.php#contact">
            <input type="hidden" name="contact_form" value="1">
            <?php if ($formSuccess): ?>
            <p class="form-note success">Merci ! Votre demande a été enregistrée. Un conseiller vous contactera sous 24 h ouvrées.</p>
            <?php elseif ($formError): ?>
            <p class="form-note error"><?php echo htmlspecialchars($formError, ENT_QUOTES, 'UTF-8'); ?></p>
            <?php endif; ?>
            <div class="form-row">
              <label for="name">Nom complet *</label>
              <input type="text" id="name" name="name" required autocomplete="name" value="<?php echo htmlspecialchars($_POST['name'] ?? '', ENT_QUOTES, 'UTF-8'); ?>">
            </div>
            <div class="form-row form-row--half">
              <div>
                <label for="email">E-mail *</label>
                <input type="email" id="email" name="email" required autocomplete="email">
              </div>
              <div>
                <label for="phone">Téléphone *</label>
                <input type="tel" id="phone" name="phone" required autocomplete="tel">
              </div>
            </div>
            <div class="form-row">
              <label for="contactCountry">Pays *</label>
              <select id="contactCountry" name="contactCountry" required>
                <option value="">Sélectionnez</option>
                <option value="fr">France</option>
                <option value="be">Belgique</option>
                <option value="lu">Luxembourg</option>
                <option value="ch">Suisse</option>
              </select>
            </div>
            <div class="form-row">
              <label for="message">Votre projet *</label>
              <textarea id="message" name="message" rows="4" required placeholder="Ex : maison 120 m², toiture sud, 6 kWc autoconsommation…"></textarea>
            </div>
            <label class="checkbox">
              <input type="checkbox" name="consent" required>
              <span>J'accepte que mes données soient traitées conformément à la <a href="legal/privacy.php">politique de confidentialité</a>.</span>
            </label>
            <button type="submit" class="btn btn--primary btn--full">Envoyer ma demande</button>
            <?php if (!$formSuccess): ?>
            <p class="form-note" id="formNote"></p>
            <?php endif; ?>
          </form>
        </div>
      </div>
    </section>
  </main>

  <footer class="footer">
    <div class="container footer__grid">
      <div>
        <a href="index.php" class="logo logo--footer">
          <span class="logo__mark">☀</span>
          <span class="logo__text">Renova <em>Solaire</em></span>
        </a>
        <p class="footer__desc">Spécialiste panneaux solaires et autoconsommation — France, Belgique, Luxembourg, Suisse.</p>
      </div>
      <div>
        <h4>Informations</h4>
        <ul>
          <li><a href="legal/mentions.php">Mentions légales</a></li>
          <li><a href="legal/privacy.php">Confidentialité</a></li>
          <li><a href="legal/cookies.php">Cookies</a></li>
          <li><a href="legal/terms.php">CGU</a></li>
        </ul>
      </div>
      <div>
        <h4>Contact</h4>
        <ul>
          <li>contact@renova-conseil.com</li>
          <li>+33 1 84 80 12 45</li>
        </ul>
      </div>
    </div>
    <div class="container footer__bottom">
      <p>© <?php echo date('Y'); ?> Renova Solaire — SAS au capital de 10 000 € · RCS Paris 912 456 789</p>
      <p class="footer__disclaimer">Les montants d'aides affichés sont indicatifs et soumis aux conditions officielles de chaque pays.</p>
    </div>
  </footer>

  <div class="cookie-banner" id="cookieBanner">
    <p>Nous utilisons des cookies pour améliorer votre expérience. <a href="legal/cookies.php">En savoir plus</a></p>
    <button class="btn btn--primary btn--sm" id="acceptCookies">Accepter</button>
  </div>

  <a href="#contact" class="mobile-cta" id="mobileCta">Devis gratuit →</a>

  <script src="js/main.js"></script>
</body>
</html>
