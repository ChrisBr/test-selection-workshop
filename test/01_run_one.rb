# Can get executed with bin/rails test test/01_run_one.rb
# We're making use of Minitest autorun
# which will execute all required tests
# https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L69-L89
# https://github.com/minitest/minitest/blob/master/lib/minitest/test.rb#L69-L81
# https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L341-L343
# https://github.com/minitest/minitest/blob/mster/lib/minitest.rb#L1111-L1116

ROOT_DIR = Pathname.new(File.dirname(__FILE__) + "/../")
require ROOT_DIR.join("test/models/article_test.rb")
