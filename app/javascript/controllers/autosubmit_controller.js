import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { delay: { type: Number, default: 250 } }

  connect() {
    this._timer = null
  }

  submit() {
    clearTimeout(this._timer)
    this._timer = setTimeout(() => {
      // If the input is inside a form, submit that form
      const form = this.element.form || this.element.closest("form")
      if (form && typeof form.requestSubmit === "function") form.requestSubmit()
    }, this.delayValue)
  }
}