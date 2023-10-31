# frozen_string_literal: true

class WaitlistEmailsController < ApplicationController
  skip_before_action :authenticate

  before_action :set_waitlist_email, only: [:confirm]

  def create
    @waitlist_email = WaitlistEmail.new(create_params)

    if @waitlist_email.save
      WaitlistMailer.with(waitlist_email: @waitlist_email).confirm_email_signup.deliver_later
      redirect_to waitlist_emails_thanks_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def thanks
  end

  def confirm
    @waitlist_email.update(confirmed_at: Time.now)
  end

  private

  def set_waitlist_email
    @waitlist_email = WaitlistEmail.find(params[:id])
  end

  def create_params
    params.require(:waitlist_email).permit(:email)
  end
end
