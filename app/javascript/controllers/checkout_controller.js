// app/javascript/controllers/checkout_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    listingId: Number // optional: set data-checkout-listing-id-value="123" on the root section
  }

  start(event) {
    event.preventDefault()

    const btn = event.currentTarget
    if (btn.dataset.loading === "1") return // double-submit guard

    // Which plan?
    const planCode = btn.dataset.checkoutPlan
    if (!planCode) {
      console.error("Missing data-checkout-plan on clicked button")
      return alert("Something went wrong. Please refresh and try again.")
    }

    // Which period?
    // 1) button can explicitly set data-checkout-period ("one_time" | "monthly" | "yearly")
    // 2) otherwise read from the UI's billing toggle (.billing-option.active data-period)
    let period = btn.dataset.checkoutPeriod
    if (!period) {
      const activeToggle = document.querySelector(".billing-toggle .billing-option.active")
      period = activeToggle?.dataset.period || "monthly"
      // Normalize to what the server expects
      if (period === "annually" || period === "annual") period = "yearly"
    }

    // Optional listing context
    const listingId = this.hasListingIdValue ? this.listingIdValue : (btn.dataset.listingId || null)

    // UI: loading state
    const originalText = btn.innerHTML
    btn.dataset.loading = "1"
    btn.disabled = true
    btn.innerHTML = `<span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span> Redirecting…`

    // CSRF
    const token = document.querySelector('meta[name="csrf-token"]')?.content

    fetch("/checkout/sessions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "X-CSRF-Token": token || ""
      },
      body: JSON.stringify({
        plan_code: planCode,
        period: period,
        listing_id: listingId
      })
    })
      .then(async (res) => {
        const data = await res.json().catch(() => ({}))
        if (!res.ok) {
          const msg = data?.error || `HTTP ${res.status}`
          throw new Error(msg)
        }
        return data
      })
      .then(({ url }) => {
        if (!url) throw new Error("No checkout URL returned")
        window.location = url
      })
      .catch((err) => {
        console.error("[Checkout] Failed:", err)
        alert(`Payment setup failed: ${err.message}`)
        btn.innerHTML = originalText
        btn.disabled = false
        btn.dataset.loading = "0"
      })
  }
}