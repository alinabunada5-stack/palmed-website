// PalMed Deutschland - Navigation, Scroll-Animationen, Zaehler, Clipboard
(function () {
  var reduced = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  // IBAN & Co. kopieren - mit Fallback fuer aeltere Browser / http
  window.copyText = function (text, btn) {
    function ok() {
      var old = btn.textContent;
      btn.textContent = "Kopiert ✓";
      setTimeout(function () { btn.textContent = old; }, 1800);
    }
    function fallback() {
      var ta = document.createElement("textarea");
      ta.value = text;
      ta.style.position = "fixed";
      ta.style.opacity = "0";
      document.body.appendChild(ta);
      ta.select();
      try { document.execCommand("copy"); ok(); } catch (e) {}
      document.body.removeChild(ta);
    }
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(ok).catch(fallback);
    } else {
      fallback();
    }
  };

  document.addEventListener("DOMContentLoaded", function () {
    // Mobile Navigation
    var toggle = document.querySelector(".nav-toggle");
    var nav = document.querySelector(".main-nav");
    if (toggle && nav) {
      function closeNav() {
        nav.classList.remove("open");
        toggle.setAttribute("aria-expanded", "false");
        toggle.setAttribute("aria-label", "Menü öffnen");
      }
      toggle.addEventListener("click", function () {
        var open = nav.classList.toggle("open");
        toggle.setAttribute("aria-expanded", String(open));
        toggle.setAttribute("aria-label", open ? "Menü schließen" : "Menü öffnen");
      });
      document.addEventListener("keydown", function (e) {
        if (e.key === "Escape" && nav.classList.contains("open")) {
          closeNav();
          toggle.focus();
        }
      });
      document.addEventListener("click", function (e) {
        if (nav.classList.contains("open") && !nav.contains(e.target) && !toggle.contains(e.target)) {
          closeNav();
        }
      });
      nav.addEventListener("click", function (e) {
        if (e.target.tagName === "A") closeNav();
      });
    }

    // Scroll-Reveals
    var els = document.querySelectorAll(
      ".card, .person, .tier, .news-item, .section-head, .timeline-item, .contact-line, .section-img, .split > .prose"
    );

    if (reduced || !("IntersectionObserver" in window)) {
      els.forEach(function (el) { el.classList.add("visible"); });
    } else {
      els.forEach(function (el) { el.classList.add("reveal"); });

      document.querySelectorAll(".card-grid, .card-grid-2, .card-grid-3, .team-grid").forEach(function (grid) {
        Array.prototype.forEach.call(grid.children, function (child, i) {
          child.style.transitionDelay = (i % 4) * 0.1 + "s";
        });
      });

      var io = new IntersectionObserver(function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) {
            entry.target.classList.add("visible");
            io.unobserve(entry.target);
          }
        });
      }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });

      els.forEach(function (el) { io.observe(el); });
    }

    // Statistiken hochzaehlen - Jahreszahlen bleiben statisch
    var nums = document.querySelectorAll(".stat .num");
    if (reduced || !("IntersectionObserver" in window) || !nums.length) return;

    var statIo = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        statIo.unobserve(entry.target);
        animateNum(entry.target);
      });
    }, { threshold: 0.6 });

    nums.forEach(function (el) { statIo.observe(el); });

    function animateNum(el) {
      var text = el.textContent.trim();
      var m = text.match(/^([\d.]+)(\+?%?)$/);
      if (!m) return;
      var useSep = m[1].indexOf(".") > -1;
      var target = parseInt(m[1].replace(/\./g, ""), 10);
      if (target >= 1900 && target <= 2100 && !useSep) return; // Jahreszahl, nicht animieren
      var suffix = m[2];
      var start = null;

      function fmt(n) {
        return useSep ? n.toLocaleString("de-DE") : String(n);
      }
      function step(ts) {
        if (start === null) start = ts;
        var p = Math.min((ts - start) / 1500, 1);
        var eased = 1 - Math.pow(1 - p, 3);
        el.textContent = fmt(Math.round(target * eased)) + suffix;
        if (p < 1) requestAnimationFrame(step);
      }
      requestAnimationFrame(step);
    }
  });
})();
