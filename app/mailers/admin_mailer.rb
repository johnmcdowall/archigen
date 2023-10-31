# frozen_string_literal: true

class AdminMailer < ApplicationMailer
  def notify_waitlist_signup
    @waitlist_email = params[:waitlist_email]

    mail(
      to: AdminConfig.email,
      subject: "New waitlist signup #{@waitlist_email}"
    )
  end
end