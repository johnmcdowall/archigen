# frozen_string_literal: true

class DisposableEmail
  class << self
    def disposable_email_domains
      @disposable_email_domains ||= File.readlines(File.join(Rails.root, 'db', 'disposable_email_domains.txt')).map(&:strip)
    end

    def disposable?(email)
      email_address = email.downcase
      email = Mail::Address.new(email_address) rescue nil

      return false unless email

      disposable_email_domains.include?(email.domain)
    end
  end
end