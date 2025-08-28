// app/javascript/controllers/home_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // Grab elements (guard if this page doesn't have them)
    const billingToggle = document.getElementById("billingToggle")
    const prices        = document.querySelectorAll(".price")
    const periods       = document.querySelectorAll(".period")

    const slider        = document.getElementById("usageSlider")
    const bubble        = document.getElementById("bubble")
    const bubbleValue   = document.getElementById("bubbleValue")
    const bubbleUnit    = document.getElementById("bubbleUnit")

    const sellersTab    = document.getElementById("sellers-tab")
    const agentsTab     = document.getElementById("agents-tab")
    const sellersPanel  = document.getElementById("sellers")
    const agentsPanel   = document.getElementById("agents")

    // If key elements are missing, exit quietly
    if (!slider || !bubble || !bubbleValue || !bubbleUnit || !sellersPanel || !agentsPanel) return

    const setBilling = () => {
      if (!billingToggle) return
      const yearly = billingToggle.checked
      prices.forEach(p => p.textContent = yearly ? p.dataset.yearly : p.dataset.monthly)
      periods.forEach(el => el.textContent = yearly ? "/yr" : "/mo")
    }

    const updateBubble = () => {
      bubbleValue.textContent = slider.value
      const val = (slider.value - slider.min) / (slider.max - slider.min || 1)
      const pct = val * 100
      bubble.style.left = `calc(${pct}% )`

      // Unit label
      if (sellersPanel.classList.contains("active")) {
        bubbleUnit.textContent = Number(slider.value) === 1 ? "Listing" : "Listings"
      } else {
        bubbleUnit.textContent = "Listings"
      }
    }

    const highlightPlan = () => {
      document.querySelectorAll(".plan-card").forEach(c => c.classList.remove("highlight"))
      const inAgents = agentsPanel.classList.contains("active")
      const value = Number(slider.value)
      const key = inAgents ? (value <= 20 ? "agents-starter" : "agents-unlimited")
                           : (value <= 1  ? "sellers-basic" : "sellers-plus")
      const card = document.querySelector(`.plan-card[data-plan="${key}"]`)
      if (card) card.classList.add("highlight")
    }

    const setSliderUI = () => {
      const tabIsAgents = agentsPanel.classList.contains("active")
      if (tabIsAgents) {
        slider.min = 1; slider.max = 120; slider.step = 1
        if (Number(slider.value) < 1) slider.value = 20
        bubbleUnit.textContent = "Listings"
      } else {
        slider.min = 1; slider.max = 2; slider.step = 1
        if (Number(slider.value) > 2) slider.value = 1
        bubbleUnit.textContent = (slider.value === "1") ? "Listing" : "Listings"
      }
      updateBubble()
      highlightPlan()
    }

    // Listeners (guard each in case element is absent)
    if (billingToggle) billingToggle.addEventListener("change", setBilling)
    slider.addEventListener("input", () => { updateBubble(); highlightPlan() })
    if (sellersTab) sellersTab.addEventListener("shown.bs.tab", setSliderUI)
    if (agentsTab)  agentsTab.addEventListener("shown.bs.tab", setSliderUI)

    // Initial render
    setBilling()
    setSliderUI()
  }
}