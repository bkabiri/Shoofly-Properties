// app/javascript/controllers/chat_autoscroll_controller.js
import { Controller } from "@hotwired/stimulus"

/**
 * Auto-scrolls a scrollable element (usually the chat body) to bottom.
 * - Scrolls on connect
 * - Scrolls after any Turbo Stream append that targets a given ID (optional)
 *
 * Usage:
 *   <div data-controller="chat-autoscroll"
 *        data-chat-autoscroll-target-id-value="messages_list_123">
 *     ...
 *   </div>
 */
export default class extends Controller {
  static values = { targetId: String } // optional

  connect() {
    this.scrollToBottom()

    // Re-scroll after a Turbo Stream update to the messages list
    this._listener = (e) => {
      // If no targetId is provided, always scroll
      if (!this.hasTargetIdValue) {
        requestAnimationFrame(() => this.scrollToBottom())
        return
      }

      try {
        const tmpl = e.target?.firstElementChild
        const target = tmpl?.getAttribute?.("target")
        if (target === this.targetIdValue) {
          requestAnimationFrame(() => this.scrollToBottom())
        }
      } catch (_) {
        // swallow
      }
    }

    document.addEventListener("turbo:before-stream-render", this._listener)
  }

  disconnect() {
    if (this._listener) {
      document.removeEventListener("turbo:before-stream-render", this._listener)
    }
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}