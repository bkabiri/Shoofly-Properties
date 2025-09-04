// app/javascript/controllers/chatinput_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "submit"]
  static values  = {
    minRows: { type: Number, default: 1 },
    maxRows: { type: Number, default: 6 },
    conversationId: Number    // <— add this
  }

  connect() {
    this.autosize()
    this.toggleSubmit()
    this._typingTimer = null
    this._isTyping = false
    this._csrf = document.querySelector('meta[name="csrf-token"]')?.content
  }

  // while typing
  input() {
    this.autosize()
    this.toggleSubmit()
  }

  // when content changes, also send "typing"
  typing() {
    this._startTyping()
  }

  keydown(e) {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault()
      if (this.textareaTarget.value.trim().length > 0) this.element.requestSubmit()
    } else {
      this._startTyping()
    }
  }

  afterSubmitStart() {
    // optimistic clear so field empties even on 204
    this._stopTyping() // stop indicator when you actually send
    this.clearBox()
  }

  afterSubmitEnd(e) {
    if (!e.detail.success) return
    this.textareaTarget.focus()
    this.toggleSubmit()
  }

  // —— helpers ——
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
    const lh = parseFloat(getComputedStyle(ta).lineHeight) || 20
    const rows = Math.min(this.maxRowsValue, Math.max(this.minRowsValue, Math.ceil(ta.scrollHeight / lh)))
    ta.rows = rows
    if (rows >= this.maxRowsValue) ta.style.overflowY = "auto"
  }

  toggleSubmit() {
    if (!this.hasSubmitTarget) return
    const disabled = this.textareaTarget.value.trim().length === 0
    this.submitTarget.toggleAttribute("disabled", disabled)
  }

  _startTyping() {
    if (!this.hasConversationIdValue) return
    if (!this._isTyping) {
      this._isTyping = true
      this._postTyping("start")
    }
    clearTimeout(this._typingTimer)
    // stop after 1.5s of inactivity
    this._typingTimer = setTimeout(() => this._stopTyping(), 1500)
  }

  _stopTyping() {
    if (!this.hasConversationIdValue) return
    if (!this._isTyping) return
    this._isTyping = false
    this._postTyping("stop")
  }

  _postTyping(status) {
    fetch(`/conversations/${this.conversationIdValue}/typing`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this._csrf
      },
      body: JSON.stringify({ status })
    }).catch(() => {})
  }
}