class AuthenticationLayout < Phlex::HTML
  include Phlex::Rails::Layout

  def template
    # The "application" layout is the default layout. It extends "base"
    # to include things like header, footer, and alerts that are common
    # to most (but not all) views.

    render BaseLayout.new do
      main class: 'min-h-full' do
        render('shared/flash')
        yield
      end
    end
  end
end
