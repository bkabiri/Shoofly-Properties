import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "placeId", "lat", "lng", "address"]

  connect() {
    // diagnostic: see it connect
    console.log("[home-search] connected")

    if (!(window.google && google.maps && google.maps.places)) {
      window.addEventListener("load", () => this.init(), { once: true })
      return
    }
    this.init()
  }

  init() {
    if (this.autocomplete) return
    console.log("[home-search] init autocomplete")

    const opts = {
      componentRestrictions: { country: ["gb"] },
      types: ["(regions)"], // remove to allow full addresses
      fields: ["place_id", "geometry", "formatted_address", "name"]
    }

    this.autocomplete = new google.maps.places.Autocomplete(this.inputTarget, opts)

    this.autocomplete.addListener("place_changed", () => {
      const place = this.autocomplete.getPlace()
      this.placeIdTarget.value = place.place_id || ""
      this.addressTarget.value = place.formatted_address || place.name || ""
      if (place.geometry?.location) {
        this.latTarget.value = place.geometry.location.lat()
        this.lngTarget.value = place.geometry.location.lng()
      } else {
        this.latTarget.value = ""
        this.lngTarget.value = ""
      }
      console.log("[home-search] place selected", {
        place_id: this.placeIdTarget.value,
        lat: this.latTarget.value,
        lng: this.lngTarget.value
      })
    })

    this.inputTarget.addEventListener("input", () => {
      this.placeIdTarget.value = ""
      this.latTarget.value = ""
      this.lngTarget.value = ""
      this.addressTarget.value = ""
    })
  }
}