import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "address", "propertyType", "bedrooms", "bathrooms",
    "publishBtn", "gallery", "banner", "description",
    "addressLine1", "addressLine2", "city", "postcode"
  ]

  connect() {
    console.debug("[listing-form] connected")
    this.validate()
    this.setupAutosave()
    this.setupPreviews()
    this.setupManualAddressSync()

    // Fallback: if data-action binding failed, wire the button by id
    const btn = document.getElementById("aiBtn")
    if (btn) {
      btn.addEventListener("click", (e) => {
        console.debug("[listing-form] fallback click")
        this.generateDescription(e)
      })
    }
  }

  validate() {
    const addressOk = this.addressProvided()
    const typeOk    = this.propertyTypeTarget?.value !== ""
    const bedsOk    = this.nonNegInt(this.bedroomsTarget?.value)
    const bathsOk   = this.nonNegInt(this.bathroomsTarget?.value)
    const ok = addressOk && typeOk && bedsOk && bathsOk
    if (this.hasPublishBtnTarget) {
      this.publishBtnTarget.disabled = !ok
      this.publishBtnTarget.classList.toggle("disabled", !ok)
    }
  }

  addressProvided() {
    const hasAuto = this.hasAddressTarget && this.addressTarget.value.trim().length > 0
    const line1 = this.hasAddressLine1Target ? this.addressLine1Target.value.trim() : ""
    const city  = this.hasCityTarget ? this.cityTarget.value.trim() : ""
    const pc    = this.hasPostcodeTarget ? this.postcodeTarget.value.trim() : ""
    const hasManual = line1 && city && pc
    return hasAuto || hasManual
  }

  requiredFilled(el) { return el && String(el.value || "").trim().length > 0 }
  nonNegInt(v) { return String(v ?? "").trim() !== "" && /^\d+$/.test(String(v)) }

  setupAutosave() {
    const form = this.element
    const status = document.getElementById("autosaveStatus")
    let timer = null

    const save = () => {
      if (!status) return
      const autosaveUrl = (form.action.endsWith("/new") || form.action.endsWith("/edit"))
        ? window.location.pathname.replace(/(new|edit)$/, "autosave")
        : window.location.pathname.replace(/\/$/, "") + "/autosave"

      status.textContent = "Saving…"
      const data = new FormData(form)
      data.set("listing[status]", "draft")
      fetch(autosaveUrl, { method: "PATCH", headers: { "X-CSRF-Token": this.csrf() }, body: data })
        .then(r => r.json())
        .then(json => { status.textContent = json.ok ? "Saved" : "Save failed" })
        .catch(() => { status.textContent = "Save failed" })
    }

    const schedule = () => {
      if (timer) clearTimeout(timer)
      timer = setTimeout(save, 15000)
    }

    this.element.addEventListener("blur", e => { if (e.target.form === this.element) save() }, true)
    this.element.addEventListener("input", () => { this.validate(); schedule() })
    schedule()
  }

  csrf() {
    const meta = document.querySelector("meta[name='csrf-token']")
    return meta ? meta.content : ""
  }

  setupPreviews() {
    const gallery = this.hasGalleryTarget ? this.galleryTarget : null
    if (gallery) {
      gallery.addEventListener("change", () => {
        const holder = document.getElementById("galleryPreviews")
        if (!holder) return
        holder.innerHTML = ""
        Array.from(gallery.files || []).slice(0, 30).forEach(file => {
          const url = URL.createObjectURL(file)
          const img = document.createElement("img")
          img.src = url
          img.className = "rounded border"
          img.style.width = "120px"
          img.style.height = "80px"
          img.style.objectFit = "cover"
          holder.appendChild(img)
        })
      })
    }
  }

  setupManualAddressSync() {
    if (!(this.hasAddressLine1Target || this.hasCityTarget || this.hasPostcodeTarget)) return
    const compose = () => {
      if (!this.hasAddressTarget) return
      if (this.addressTarget.value.trim().length > 0) return
      const parts = []
      if (this.hasAddressLine1Target && this.addressLine1Target.value.trim()) parts.push(this.addressLine1Target.value.trim())
      if (this.hasAddressLine2Target && this.addressLine2Target.value.trim()) parts.push(this.addressLine2Target.value.trim())
      if (this.hasCityTarget && this.cityTarget.value.trim()) parts.push(this.cityTarget.value.trim())
      if (this.hasPostcodeTarget && this.postcodeTarget.value.trim()) parts.push(this.postcodeTarget.value.trim())
      const composed = parts.join(", ")
      if (composed.length > 0) {
        this.addressTarget.value = composed
        this.addressTarget.dispatchEvent(new Event("input", { bubbles: true }))
      }
    }
    const events = ["input", "change", "blur"]
    ;[this.addressLine1Target, this.addressLine2Target, this.cityTarget, this.postcodeTarget]
      .filter(Boolean)
      .forEach(el => events.forEach(ev => el.addEventListener(ev, compose)))
  }

  // --------- AI: Generate description ----------
  async generateDescription(event) {
    event.preventDefault()
    console.debug("[listing-form] generateDescription clicked")
    const btn = event.currentTarget
    btn.disabled = true
    const original = btn.textContent
    btn.textContent = "Generating…"

    try {
      const raw = window.location.pathname.replace(/\/$/, "")
      const isNew = /\/new$/.test(raw)
      const memberBase = raw.replace(/\/edit$/, "")        // ✅ strip /edit
      const url = isNew ? "/seller/listings/generate_description"
                        : `${memberBase}/generate_description`

      const body = new FormData()
      let addr = this.hasAddressTarget ? this.addressTarget.value.trim() : ""
      if (!addr) {
        const parts = []
        if (this.hasAddressLine1Target && this.addressLine1Target.value.trim()) parts.push(this.addressLine1Target.value.trim())
        if (this.hasAddressLine2Target && this.addressLine2Target.value.trim()) parts.push(this.addressLine2Target.value.trim())
        if (this.hasCityTarget && this.cityTarget.value.trim()) parts.push(this.cityTarget.value.trim())
        if (this.hasPostcodeTarget && this.postcodeTarget.value.trim()) parts.push(this.postcodeTarget.value.trim())
        addr = parts.join(", ")
      }

      body.set("address", addr)
      body.set("property_type", this.hasPropertyTypeTarget ? this.propertyTypeTarget.value : "")
      body.set("bedrooms", this.hasBedroomsTarget ? this.bedroomsTarget.value : "")
      body.set("bathrooms", this.hasBathroomsTarget ? this.bathroomsTarget.value : "")

      console.debug("[listing-form] POST", url)
      const res = await fetch(url, { method: "POST", headers: { "X-CSRF-Token": this.csrf() }, body })
      const json = await res.json()
      console.debug("[listing-form] response", json)

      if (json.ok && this.hasDescriptionTarget) {
        this.descriptionTarget.value = json.description.trim()
        this.descriptionTarget.dispatchEvent(new Event("input", { bubbles: true }))
      } else {
        alert(json.error || "Could not generate description")
      }
    } catch (e) {
      console.error("[listing-form] error", e)
      alert("Network error while generating description")
    } finally {
      btn.disabled = false
      btn.textContent = original
    }
  }
}