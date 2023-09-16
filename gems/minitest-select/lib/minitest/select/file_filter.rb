module Minitest
  module Select
    class FileFilter
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

        test_files_to_run_based_on_test_map.include?(source_location_for(other))
      rescue => error
        # In case of an error we want to be on the safe side and run all tests
        puts "Error while filtering test #{other}: #{error.message}"
        true
      end

      def source_location_for(test_id)
        # === will get called with e.g. ArticleTest#test_foo
        # We use the klass (ArticleTest) to get the source location and check if it's included in our test selection
        klass, method_name = test_id.split("#", 2)

        normalize(klass.constantize.new(method_name).method(method_name).source_location.first)
      end

      def normalize(path)
        path.delete_prefix(PROJECT_ROOT)
      end

      def test_files_to_run_based_on_test_map
        @test_files_to_run_based_on_test_map ||= @changed_files.to_a.map do |file|
          @test_map.fetch(file.squish)
        end.flatten
      end
    end
  end
end
