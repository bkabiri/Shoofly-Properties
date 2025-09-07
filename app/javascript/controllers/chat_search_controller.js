import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="chat-search"
export default class extends Controller {
  static targets = ["input", "item"]

  connect() {
    // optional: focus search box on connect
    // this.inputTarget.focus()
  }

  filter() {
    const query = this.inputTarget.value.toLowerCase()

    this.itemTargets.forEach((el) => {
      const name = el.dataset.chatName || ""
      if (name.includes(query)) {
        el.classList.remove("d-none")
      } else {
        el.classList.add("d-none")
      }
    })
  }
}