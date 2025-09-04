// app/javascript/controllers/chatinput_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit"]
  static values  = { minRows: { type: Number, default: 1 }, maxRows: { type: Number, default: 6 } }

  connect() {
    this.autosize()
    this.toggleSubmit()
  }

  // Grow/shrink + enable/disable submit while typing
  input() {
    this.autosize()
    this.toggleSubmit()
  }

  // Enter = send, Shift+Enter = new line
  keydown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      if (this.textareaTarget.value.trim().length > 0) this.element.requestSubmit()
    }
  }

  // Turbo says the request is going out (optimistically clear)
  afterSubmitStart() {
    // Clear immediately so the field empties even when server returns 204
    this.clearBox()
  }

  // Turbo says the request finished (keep focus, re-disable submit)
  afterSubmitEnd(e) {
    // If it failed, don’t leave a ghost value
    if (!e.detail.success) return
    this.textareaTarget.focus()
    this.toggleSubmit()
  }

  // — helpers —
  clearBox() {
    this.textareaTarget.value = ""
    this.autosize()
    this.toggleSubmit()
  }

  autosize() {
    const ta = this.textareaTarget
    ta.rows = this.minRowsValue
    ta.style.height = "auto"
    ta.style.overflowY = "hidden"

    const lineHeight = parseFloat(getComputedStyle(ta).lineHeight) || 20
    const rowsNeeded = Math.min(this.maxRowsValue,
      Math.max(this.minRowsValue, Math.ceil(ta.scrollHeight / lineHeight)))
    ta.rows = rowsNeeded
    if (rowsNeeded >= this.maxRowsValue) ta.style.overflowY = "auto"
  }

  toggleSubmit() {
    if (!this.hasSubmitTarget) return
    const disabled = this.textareaTarget.value.trim().length === 0
    this.submitTarget.toggleAttribute("disabled", disabled)
  }
}