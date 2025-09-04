// app/javascript/controllers/auto_scroll_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.scroll()
    document.addEventListener("turbo:before-stream-render", () => {
      requestAnimationFrame(() => this.scroll())
    })
  }

  scroll() {
    this.element.scrollTop = this.element.scrollHeight
  }
}