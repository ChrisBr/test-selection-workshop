require "action_dispatch"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test
end
