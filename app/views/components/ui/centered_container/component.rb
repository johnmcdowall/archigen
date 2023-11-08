module UI::CenteredContainer
  class Component < ApplicationComponent
    attr_reader :kwargs

    def initialize(**kwargs)
      super
      @kwargs = kwargs
    end

    def template(&)
      div(
        class: tokens(
          'flex flex-col items-center justify-center h-full',
          -> { kwargs[:class] } => kwargs[:class]
        ),
        &
      )
    end
  end
end
