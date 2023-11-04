module Sitepress
  class SiteController < ::ApplicationController
    include Sitepress::SitePages

    protected

    def phlex_component?(view_name)
      view_name.instance_of?(String) && view_name.constantize < Phlex::HTML
    rescue NameError
      false
    end

    # This is where the actual rendering happens for the page source in Rails.
    #
    # JMD: Have to override this to handle when a content page has a frontmatter that says:
    # ---
    # layout: PageLayout
    # ---
    def pre_render(rendition)
      final_layout = if phlex_component?(rendition.layout)
                       proc { rendition.layout.constantize }
                     else
                       rendition.layout
                     end

      rendition.output = render_to_string inline: rendition.source,
                                          type: rendition.handler,
                                          layout: final_layout
    end

    # Returns the current layout for the inline Sitepress renderer. This is
    # exposed via some really convoluted private methods inside of the various
    # versions of Rails, so I try my best to hack out the path to the layout below.
    def controller_layout
      private_layout_method = method(:_layout)
      layout =
        if Rails.version >= '6'
          private_layout_method.call lookup_context, current_resource_rails_formats
        elsif Rails.version >= '5'
          private_layout_method.call current_resource_rails_formats
        else
          private_layout_method.call
        end

      if phlex_component?(layout)
        proc { layout }
      elsif layout.instance_of? String # Rails 4 and 5 return a string from above. Phlex we handle
        layout
      elsif layout # Rails 3 and older return an object that gives us a file name
        File.basename(layout.identifier).split('.').first
      end
    end
  end
end
