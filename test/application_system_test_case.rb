require "capybara/cuprite"
require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite, using: :headless_chrome, screen_size: [1400, 1400]
end
