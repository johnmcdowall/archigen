# frozen_string_literal: true

class WaitlistMailer < ApplicationMailer
  def confirm_email_signup
    waitlist_email = params[:waitlist_email]
    @waitlist_email_id = waitlist_email.id

    mail(
      to: waitlist_email.email,
      subject: "Please confirm your addition to the waitlist for #{ApplicationController.helpers.application_name}"
    )
  end
end
