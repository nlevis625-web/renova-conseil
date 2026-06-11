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

  if (cookieBanner && !localStorage.getItem("renovia_cookies")) {
    cookieBanner.classList.remove("hidden");
  } else if (cookieBanner) {
    cookieBanner.classList.add("hidden");
  }

  if (acceptCookies) {
    acceptCookies.addEventListener("click", function () {
      localStorage.setItem("renovia_cookies", "1");
      cookieBanner.classList.add("hidden");
    });
  }

  var aidEstimates = {
    fr: {
      pac: { modest: 8000, intermediate: 5000, high: 3000 },
      isolation: { modest: 6000, intermediate: 4000, high: 2000 },
      solaire: { modest: 4000, intermediate: 2500, high: 1500 },
      global: { modest: 15000, intermediate: 10000, high: 6000 }
    },
    be: {
      pac: { modest: 6000, intermediate: 4000, high: 2500 },
      isolation: { modest: 5000, intermediate: 3000, high: 1500 },
      solaire: { modest: 3500, intermediate: 2000, high: 1000 },
      global: { modest: 12000, intermediate: 8000, high: 5000 }
    },
    lu: {
      pac: { modest: 7000, intermediate: 4500, high: 2800 },
      isolation: { modest: 5500, intermediate: 3500, high: 1800 },
      solaire: { modest: 3800, intermediate: 2200, high: 1200 },
      global: { modest: 13000, intermediate: 9000, high: 5500 }
    },
    ch: {
      pac: { modest: 5000, intermediate: 3500, high: 2000 },
      isolation: { modest: 4000, intermediate: 2500, high: 1200 },
      solaire: { modest: 3000, intermediate: 1800, high: 800 },
      global: { modest: 10000, intermediate: 7000, high: 4000 }
    }
  };

  var countryLabels = {
    fr: "France",
    be: "Belgique",
    lu: "Luxembourg",
    ch: "Suisse"
  };

  var projectLabels = {
    pac: "pompe à chaleur air-eau",
    isolation: "isolation thermique",
    solaire: "panneaux solaires",
    global: "rénovation globale"
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
      var surface = parseInt(document.getElementById("surface").value, 10) || 100;

      if (!country || !project || !income) return;

      var base = aidEstimates[country][project][income];
      var surfaceFactor = Math.min(surface / 100, 1.5);
      var estimate = Math.round(base * surfaceFactor);

      resultAmount.textContent = "Jusqu'à " + estimate.toLocaleString("fr-FR") + " €";
      resultDetail.textContent =
        "Estimation pour un projet de " + projectLabels[project] +
        " en " + countryLabels[country] +
        " (logement ~" + surface + " m²). Montant indicatif cumulable selon dispositifs officiels.";

      simulatorResult.hidden = false;
      simulatorResult.scrollIntoView({ behavior: "smooth", block: "nearest" });
    });
  }

  var contactForm = document.getElementById("contactForm");
  var formNote = document.getElementById("formNote");

  if (contactForm) {
    contactForm.addEventListener("submit", function (e) {
      e.preventDefault();
      formNote.textContent = "Merci ! Votre demande a été enregistrée. Un conseiller vous contactera sous 24 h ouvrées.";
      formNote.className = "form-note success";
      contactForm.reset();
    });
  }
})();
