import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["email", "password", "loginBtn", "togglePassword"]

  connect() {
    this.updateBtn()
  }

  updateBtn() {
    const ready = this.emailTarget.value.trim() !== "" && this.passwordTarget.value.trim() !== ""
    if (ready) {
      this.loginBtnTarget.disabled = false
      this.loginBtnTarget.classList.add("enabled")
    } else {
      this.loginBtnTarget.disabled = true
      this.loginBtnTarget.classList.remove("enabled")
    }
  }

  togglePassword() {
    const type = this.passwordTarget.getAttribute("type") === "password" ? "text" : "password"
    this.passwordTarget.setAttribute("type", type)
    this.togglePasswordTarget.innerHTML = type === "password"
      ? '<i class="far fa-eye"></i>'
      : '<i class="far fa-eye-slash"></i>'
  }
}