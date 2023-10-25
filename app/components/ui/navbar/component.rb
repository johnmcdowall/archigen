class UI::Navbar::Component < ApplicationViewComponent
  option :disable_mobile_nav, default: proc { false }

  renders_one :left
  renders_one :center
  renders_one :right
  renders_one :mobile_menu
end
