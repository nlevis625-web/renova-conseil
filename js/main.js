(function () {
  "use strict";

  var menuToggle = document.getElementById("menuToggle");
  var nav = document.getElementById("nav");

  if (menuToggle && nav) {
    menuToggle.addEventListener("click", function () {
      nav.classList.toggle("open");
    });
    nav.querySelectorAll("a").forEach(function (link) {
      link.addEventListener("click", function () {
        nav.classList.remove("open");
      });
    });
  }

  var cookieBanner = document.getElementById("cookieBanner");
  var acceptCookies = document.getElementById("acceptCookies");

  if (cookieBanner && !localStorage.getItem("renova_cookies")) {
    cookieBanner.classList.remove("hidden");
  } else if (cookieBanner) {
    cookieBanner.classList.add("hidden");
  }

  if (acceptCookies) {
    acceptCookies.addEventListener("click", function () {
      localStorage.setItem("renova_cookies", "1");
      cookieBanner.classList.add("hidden");
    });
  }

  var aidEstimates = {
    fr: {
      solaire: { modest: 4000, intermediate: 2500, high: 1500 },
      "solaire-batterie": { modest: 6000, intermediate: 4000, high: 2500 },
      "solaire-revente": { modest: 3500, intermediate: 2000, high: 1000 }
    },
    be: {
      solaire: { modest: 3500, intermediate: 2000, high: 1000 },
      "solaire-batterie": { modest: 5500, intermediate: 3500, high: 2000 },
      "solaire-revente": { modest: 3000, intermediate: 1800, high: 800 }
    },
    lu: {
      solaire: { modest: 3800, intermediate: 2200, high: 1200 },
      "solaire-batterie": { modest: 5800, intermediate: 3800, high: 2200 },
      "solaire-revente": { modest: 3200, intermediate: 1900, high: 900 }
    },
    ch: {
      solaire: { modest: 3000, intermediate: 1800, high: 800 },
      "solaire-batterie": { modest: 5000, intermediate: 3200, high: 1800 },
      "solaire-revente": { modest: 2500, intermediate: 1500, high: 600 }
    }
  };

  var countryLabels = { fr: "France", be: "Belgique", lu: "Luxembourg", ch: "Suisse" };
  var projectLabels = {
    solaire: "panneaux solaires (autoconsommation)",
    "solaire-batterie": "panneaux solaires avec batterie",
    "solaire-revente": "revente totale au réseau"
  };

  var simulatorForm = document.getElementById("simulatorForm");
  var simulatorResult = document.getElementById("simulatorResult");
  var resultAmount = document.getElementById("resultAmount");
  var resultDetail = document.getElementById("resultDetail");

  if (simulatorForm) {
    simulatorForm.addEventListener("submit", function (e) {
      e.preventDefault();
      var country = document.getElementById("country").value;
      var project = document.getElementById("project").value;
      var income = document.getElementById("income").value;
      var kwc = parseInt(document.getElementById("surface").value, 10) || 6;

      if (!country || !project || !income) return;

      var base = aidEstimates[country][project][income];
      var kwcFactor = Math.min(kwc / 6, 2);
      var estimate = Math.round(base * kwcFactor);

      resultAmount.textContent = "Jusqu'à " + estimate.toLocaleString("fr-FR") + " €";
      resultDetail.textContent =
        "Estimation pour " + projectLabels[project] +
        " en " + countryLabels[country] +
        " (~" + kwc + " kWc). Montant indicatif cumulable selon dispositifs officiels.";

      simulatorResult.hidden = false;
      simulatorResult.scrollIntoView({ behavior: "smooth", block: "nearest" });
    });
  }

  var contactForm = document.getElementById("contactForm");
  var formNote = document.getElementById("formNote");

  if (contactForm && formNote && !formNote.classList.contains("success")) {
    contactForm.addEventListener("submit", function () {
      var btn = contactForm.querySelector('button[type="submit"]');
      if (btn) {
        btn.disabled = true;
        btn.textContent = "Envoi en cours…";
      }
    });
  }

  var mobileCta = document.getElementById("mobileCta");
  var contactSection = document.getElementById("contact");

  if (mobileCta && contactSection) {
    var toggleMobileCta = function () {
      var rect = contactSection.getBoundingClientRect();
      var hide = rect.top < window.innerHeight * 0.6;
      mobileCta.classList.toggle("hidden", hide);
    };
    window.addEventListener("scroll", toggleMobileCta, { passive: true });
    toggleMobileCta();
  }

  if (window.location.hash === "#contact" || document.querySelector(".form-note.success")) {
    var target = document.getElementById("contact");
    if (target) target.scrollIntoView({ behavior: "smooth" });
  }
})();
