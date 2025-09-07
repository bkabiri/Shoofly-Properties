// app/javascript/confirm_adapter.js
document.addEventListener("turbo:before-fetch-request", (event) => {
  const el = event.target; // the link/button/form that initiated the request
  const msg = el?.dataset?.turboConfirm;
  if (!msg) return;

  if (!window.confirm(msg)) {
    event.preventDefault();
  }
});