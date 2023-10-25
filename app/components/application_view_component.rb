# frozen_string_literal: true

require 'dry-initializer'

class ApplicationViewComponent < ViewComponentContrib::Base
  extend Dry::Initializer
  using HTMLAttributesUtils

  attr_reader :html_attributes

  def initialize(classes: [], html_attributes: {}, **args)
    @html_attributes = default_attributes
      .deep_merge_html_attributes({class: classes})
      .deep_merge_html_attributes(html_attributes)
      .deep_tidy_html_attributes

    super(**args)
  end

  # the same as above
  def identifier
    @identifier ||= self.class.name.sub("::Component", "").underscore.split("/").join("--")
  end

  # We also add an ability to build a class from a different component
  def class_for(name, from: identifier)
    "c-#{from}-#{name}"
  end

  def default_attributes
    {}
  end
end
