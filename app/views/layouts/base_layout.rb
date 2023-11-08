# The "base" layout contains boilerplate common to *all* views.

class BaseLayout < Phlex::HTML
  include Phlex::Rails::Layout

  def template
    doctype

    html lang: "en", class: "antialiased scroll-smooth text-base min-h-full" do
      head do
        comment { %(Archigentest  (#{Rails.application.config.version}) (#{Rails.application.config.version_time})) }

        plain helpers.metamagic(
          site: "Archigentest",
          title: -> { current_page_title ? "#{current_page_title} - #{site}" : site },
          separator: " \u2013 ",
          description: "Archigentest description.",
          keywords: "Archigentest Keywords",
          og: {
            site_name: "Site name",
            title: "Site title",
            description: "Site description"
            # image: image_url('open-graph.jpg')
          }
        )

        # Specifies the default name of home screen bookmark in iOS
        meta(name: %(apple-mobile-web-app-title), content: %(Archigentest))
        meta(name: %(viewport), content: %(width=device-width,initial-scale=1))
        plain helpers.csrf_meta_tags
        plain helpers.csp_meta_tag
        plain helpers.vite_client_tag
        plain helpers.vite_javascript_tag "application", "data-turbo-track": "reload"
        plain helpers.vite_stylesheet_tag "application", "data-turbo-track": "reload"
        comment do
          %(If using a TypeScript entrypoint file: vite_typescript_tag 'application' If using a .jsx or .tsx entrypoint, add the extension: vite_javascript_tag 'application.jsx' Visit the guide for more information: https://vite-ruby.netlify.app/guide/rails)
        end
        yield(:head)
      end
    end

    body(class: "flex flex-col min-h-full bg-background-plate min-h-full")
  end
end
