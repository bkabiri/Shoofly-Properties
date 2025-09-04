// app/javascript/controllers/autoscroll_controller.js
import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  connect() { this.scroll() }
  scroll() { this.element.scrollTop = this.element.scrollHeight }
}
