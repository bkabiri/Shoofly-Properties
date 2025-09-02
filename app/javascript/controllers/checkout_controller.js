// app/javascript/controllers/checkout_controller.js
import { Controller } from "@hotwired/stimulus"

// Requires Bootstrap's JS to be loaded globally (for Modal)
export default class extends Controller {
  static values = {
    listingId: Number,                 // optional: passes a listing_id along
    endpoint: { type: String, default: "/checkout/sessions" } // if you use a named route, set via data-checkout-endpoint-value
  }

  connect() {
    this.modalEl   = document.getElementById("planPreviewModal")
    this.bsModal   = this.modalEl ? new bootstrap.Modal(this.modalEl) : null
    this.confirmEl = this.modalEl?.querySelector("[data-checkout-confirm]")

    if (this.confirmEl) {
      this.confirmEl.addEventListener("click", () => this.confirm())
    }
  }

  // Step 1: open modal with details from the clicked card
  preview(event) {
    const btn  = event.currentTarget
    const card = btn.closest("[data-plan-card]")
    if (!card || !this.bsModal) return

    // Read visible data from the card
    const name   = card.querySelector(".plan-name")?.textContent?.trim() || "Selected plan"
    const price  = card.querySelector(".plan-price")?.textContent?.trim() || "£—"
    const period = card.querySelector(".plan-period")?.textContent?.trim() || ""

    const features = Array.from(card.querySelectorAll(".plan-features .feature-item"))
      .map(el => el.textContent.trim())
      .filter(Boolean)

    // Stash payload for confirm()
    this.pending = {
      plan_code: btn.dataset.checkoutPlan,
      plan_kind: btn.dataset.checkoutKind || "subscription",
      period:    btn.dataset.checkoutPeriod || "monthly",
      listing_id: this.hasListingIdValue ? this.listingIdValue : null
    }

    // Populate modal
    this.modalEl.querySelector("#previewPlanName").textContent   = name
    this.modalEl.querySelector("#previewPlanPrice").textContent  = price
    this.modalEl.querySelector("#previewPlanPeriod").textContent = period

    const container = this.modalEl.querySelector("#previewPlanFeatures")
    container.innerHTML = ""
    features.forEach(txt => {
      const row = document.createElement("div")
      row.className = "feat"
      row.innerHTML = `<i class="bi bi-check-circle-fill"></i><div>${txt}</div>`
      container.appendChild(row)
    })

    this.bsModal.show()
  }

  // Step 2: user clicks "Continue to Checkout"
  confirm() {
    if (!this.pending) return
    this.startWith(this.pending)
  }

  // Fallback direct-start (if you still call data-action="click->checkout#start" somewhere)
  start(event) {
    const btn = event?.currentTarget
    const payload = {
      plan_code: btn?.dataset.checkoutPlan,
      plan_kind: btn?.dataset.checkoutKind || "subscription",
      period:    btn?.dataset.checkoutPeriod || "monthly",
      listing_id: this.hasListingIdValue ? this.listingIdValue : null
    }
    this.startWith(payload, btn)
  }

  startWith(payload, btn = null) {
    if (btn) btn.disabled = true
    if (this.confirmEl) this.confirmEl.disabled = true

    fetch(this.endpointValue || "/checkout/sessions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(payload)
    })
      .then(r => r.json())
      .then(({ url, error }) => {
        if (error) throw new Error(error)
        // Close modal before redirecting
        if (this.bsModal) this.bsModal.hide()
        window.location = url
      })
      .catch(err => {
        console.error(err)
        alert(`Could not start checkout: ${err.message}`)
      })
      .finally(() => {
        if (btn) btn.disabled = false
        if (this.confirmEl) this.confirmEl.disabled = false
      })
  }
}