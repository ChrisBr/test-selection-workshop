# Can be executed by e.g.
# bin/rails test --select-file=test/models/article_test.rb
module Minitest
  module Select
    class FileFilter
      def initialize(expected_path)
        @expected_path = expected_path
      end

      # Minitest calls this method with test_method_name and TestKlass#test_method_name
      # https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L341-L343
      def ===(other)
        # other will either be test_name (test_foo) or Klass#test_name (ArticleTest#test_foo)
        # we're only interested in the full test_id because only this allows us to get the source_location
        return false unless other.include?("#")

        # Minitest only provides a string of the test_id e.g. ArticleTest#test_foo
        # We need to split ArticleTest#test_foo to get the klass and method name
        # which we can use to find the file which defines the test
        klass, method_name = other.split("#", 2)
        path = klass.constantize.new(method_name).method(method_name).source_location.first
        path = path.delete_prefix(PROJECT_ROOT)

        result = path == @expected_path
        puts "Skipping '#{other}' (not in #{@expected_path})" unless result
        result
      end
    end
  end
end
