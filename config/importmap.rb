pin "application"
pin "@hotwired/turbo-rails",       to: "turbo.min.js", preload: true
pin "@hotwired/stimulus",          to: "stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading",  to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "confirm_adapter", to: "confirm_adapter.js" # since you import it directly