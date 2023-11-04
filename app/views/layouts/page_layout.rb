class PageLayout < Phlex::HTML
  include Phlex::Rails::Layout

  def template
    # The "application" layout is the default layout. It extends "base"
    # to include things like header, footer, and alerts that are common
    # to most (but not all) views.

    render BaseLayout.new do
      render('shared/nav')
      main class: 'prose container mx-auto max-w-4xl xl:max-w-5xl mt-32 md:mt-48 px-4 lg:px-0' do
        render('shared/flash')
        yield
      end
      render('shared/footer')
    end
  end
end
