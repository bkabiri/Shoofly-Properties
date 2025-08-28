// app/javascript/controllers/address_autocomplete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "placeId", "lat", "lng"]

  connect() {
    if (!window.google || !window.google.maps) return

    this.autocomplete = new google.maps.places.Autocomplete(this.inputTarget, {
      fields: ["address_components", "geometry", "place_id", "formatted_address"],
      types: ["address"]
    })

    this.autocomplete.addListener("place_changed", this.fillIn.bind(this))
  }

  fillIn() {
    const place = this.autocomplete.getPlace()
    if (!place) return

    // Store hidden fields
    this.placeIdTarget.value = place.place_id || ""
    this.latTarget.value = place.geometry?.location?.lat() || ""
    this.lngTarget.value = place.geometry?.location?.lng() || ""

    // Autofill manual fields if they exist
    const comps = place.address_components || []
    const getComp = (type) => comps.find(c => c.types.includes(type))?.long_name || ""

    const line1  = `${getComp("street_number")} ${getComp("route")}`.trim()
    const line2  = getComp("sublocality") || ""
    const city   = getComp("locality") || getComp("postal_town")
    const postcode = getComp("postal_code")

    const line1El = document.querySelector("#listing_address_line1")
    const line2El = document.querySelector("#listing_address_line2")
    const cityEl  = document.querySelector("#listing_city")
    const postEl  = document.querySelector("#listing_postcode")

    if (line1El) line1El.value = line1
    if (line2El) line2El.value = line2
    if (cityEl)  cityEl.value  = city
    if (postEl)  postEl.value  = postcode

    // Force open the manual section
    const collapseEl = document.getElementById("manualAddress")
    if (collapseEl && !collapseEl.classList.contains("show")) {
      const bsCollapse = bootstrap.Collapse.getOrCreateInstance(collapseEl, { toggle: false })
      bsCollapse.show()
    }
  }
}