# https://github.com/minitest/minitest#adding-custom-reporters-
# bin/rails test --select-simple
module Minitest
  module Select
    module Reporters
      class SimpleReporter < Minitest::Reporter
        def initialize(options); end

        def start
          puts "SimpleReporter started"
        end

        def prerecord(klass, name)
          puts
          puts "Starting #{klass}##{name}"
        end

        def record(result)
          puts "Finished #{result.klass}##{result.name}<#{result.source_location.first}>"
        end

        def report
          puts "SimpleReporter finished"
        end
      end
    end
  end
end
