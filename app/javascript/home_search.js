// app/javascript/home_search.js
(function() {
  function setupAutocomplete() {
    var input = document.getElementById('homeSearchInput');
    if (!input || !window.google || !google.maps || !google.maps.places) return;

    // Restrict to the UK; tweak as needed
    var options = {
      componentRestrictions: { country: ['gb'] },
      // Region-type results (cities, postcodes, areas). Remove types if you want addresses too.
      types: ['(regions)'],
      fields: ['place_id', 'geometry', 'formatted_address', 'name']
    };

    var autocomplete = new google.maps.places.Autocomplete(input, options);

    autocomplete.addListener('place_changed', function() {
      var place = autocomplete.getPlace();
      var placeIdField = document.getElementById('placeIdField');
      var latField     = document.getElementById('latField');
      var lngField     = document.getElementById('lngField');
      var addrField    = document.getElementById('formattedAddressField');

      if (placeIdField) placeIdField.value = place.place_id || '';
      if (addrField)    addrField.value    = place.formatted_address || place.name || '';

      if (place.geometry && place.geometry.location) {
        var loc = place.geometry.location;
        if (latField) latField.value = loc.lat();
        if (lngField) lngField.value = loc.lng();
      } else {
        // No geometry? Clear coords so backend can fall back to text search
        if (latField) latField.value = '';
        if (lngField) lngField.value = '';
      }
    });

    // Optional: submit on Enter when a place is selected
    input.addEventListener('keydown', function(e) {
      if (e.key === 'Enter') {
        // Let Places handle enter when the dropdown is open; otherwise form submits.
        // No custom handling required.
      }
    });
  }

  // Global callback for script tag
  window.initHomeSearch = function() {
    setupAutocomplete();
  };

  // As a fallback if script is cached and callback already fired
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    setTimeout(setupAutocomplete, 0);
  } else {
    document.addEventListener('DOMContentLoaded', setupAutocomplete);
  }
})();