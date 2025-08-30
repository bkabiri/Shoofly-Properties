// app/javascript/controllers/stripe_checkout_controller.js
import { Controller } from "@hotwired/stimulus"
import { loadStripe } from "@stripe/stripe-js"

export default class extends Controller {
  static values = {
    mode: String,              // "payment" | "subscription" (read from clicked button)
    priceId: String,           // optional (for subscriptions / static prices)
    amountPence: Number,       // optional (for one-time dynamic)
    name: String               // optional (for one-time dynamic)
  }

  async start(event) {
    event.preventDefault()

    const btn = event.currentTarget
    const mode        = btn.dataset.stripeCheckoutModeValue
    const priceId     = btn.dataset.stripeCheckoutPriceIdValue
    const amountPence = btn.dataset.stripeCheckoutAmountPenceValue
    const name        = btn.dataset.stripeCheckoutNameValue

    try {
      const pk = document.querySelector('meta[name="stripe-publishable-key"]').content
      const stripe = await loadStripe(pk)

      // Build payload for /checkout/sessions
      const payload = { mode }
      if (priceId)     payload.price_id = priceId
      if (amountPence) payload.amount_pence = parseInt(amountPence, 10)
      if (name)        payload.name = name

      const res = await fetch("/checkout/sessions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(payload)
      })

      if (!res.ok) {
        const err = await res.json().catch(() => ({}))
        throw new Error(err.error || "Server error")
      }

      const data = await res.json()
      const { error } = await stripe.redirectToCheckout({ sessionId: data.id })
      if (error) throw error
    } catch (e) {
      console.error(e)
      alert("Could not start checkout. Please try again.")
    }
  }
}