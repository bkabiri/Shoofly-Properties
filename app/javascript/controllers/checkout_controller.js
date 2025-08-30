// app/javascript/controllers/checkout_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  start(event) {
    const btn = event.currentTarget
    const planCode = btn.dataset.checkoutPlan
    const planKind = btn.dataset.checkoutKind || "subscription"
    const period   = btn.dataset.checkoutPeriod || "monthly"

    btn.disabled = true

    fetch("/checkout/sessions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ plan_code: planCode, plan_kind: planKind, period })
    })
      .then(r => r.json())
      .then(({ url, error }) => {
        if (error) throw new Error(error)
        window.location = url
      })
      .catch(err => {
        console.error(err)
        alert(`Payment setup failed: ${err.message}`)
      })
      .finally(() => { btn.disabled = false })
  }
}