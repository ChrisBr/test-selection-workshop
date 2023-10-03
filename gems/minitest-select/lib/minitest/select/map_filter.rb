# Can be executed by e.g.
# bin/rails test --verbose --select-run --select-changed-files=test/models/article_test.rb test/**/*_test.rb
module Minitest
  module Select
    class MapFilter
      def initialize(test_map, config, changed_files)
        @test_map = test_map
        @config = config
        @changed_files = changed_files
      end

      # Before executing a test, Minitest will call the filter method with test_name and test_id
      # https://github.com/minitest/minitest/blob/6719ad8d8d49779669083f5029ea9a0429c49ff5/lib/minitest.rb#L341-L343
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

        test_files_to_run.include?(path)
      rescue => error
        # In case of an error we want to be on the safe side and run all tests
        puts "Error while filtering test #{other}: #{error.message}"
        true
      end

      def test_files_to_run
        @test_files_to_run ||= test_files_to_run_based_on_test_map
      end

      def test_files_to_run_based_on_test_map
        changed_files.to_a.map do |file|
          @test_map.fetch(file.squish)
        end.flatten
      end

      def changed_files
        @changed_files - @config["ignore"].to_a
      end
    end
  end
end
