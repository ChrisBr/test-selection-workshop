module Minitest
  module Select
    class MinLengthFilter
      def initialize(length)
        @length = length
      end

      def ===(other)
        # Minitest calls this method with test_method_name and TestKlass#test_method_name
        # https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L341-L343
        other.length > @length
      end
    end
  end
end
