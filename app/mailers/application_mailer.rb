class ApplicationMailer < ActionMailer::Base
  default from: "Snoofly <#{ENV.fetch("MAILER_SENDER", "no-reply@snoofly.co.uk")}>"
  layout "mailer"
end
