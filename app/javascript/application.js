// Entry point for the build
import "@hotwired/turbo-rails"
import "controllers"
import "confirm_adapter"

window.Turbo = Turbo
Turbo.session.drive = true
// Ensure Bootstrap Offcanvas opens even with Turbo
document.addEventListener("turbo:load", () => {
  const el = document.getElementById("mainMenu");
  if (!el || typeof bootstrap === "undefined") return;

  // create or reuse the instance
  const oc = bootstrap.Offcanvas.getOrCreateInstance(el);

  // bind all triggers pointing at #mainMenu
  document.querySelectorAll('[data-bs-target="#mainMenu"]').forEach(btn => {
    btn.addEventListener("click", (e) => {
      e.preventDefault();
      oc.show();
    });
  });
});