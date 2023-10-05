require "capybara/cuprite"
require "action_dispatch"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :rack_test, screen_size: [1400, 1400]
end
