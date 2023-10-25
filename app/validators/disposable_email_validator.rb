# frozen_string_literal: true

class DisposableEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    if DisposableEmail.disposable?(value)
      record.errors.add(attribute, (options[:message] || "Email is not allowed to be a disposable email."))
    end
  end
end