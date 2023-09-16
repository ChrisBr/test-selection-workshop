# https://github.com/minitest/minitest#adding-custom-reporters-
# Can be executed with e.g.
# bin/rails test --select-trace test/controllers/articles_controller_test.rb:8
module Minitest
  module Select
    module Reporters
      class TraceReporter < Minitest::Reporter
        def initialize(options); end

        def normalized_path(path)
          # We need to remove the project root to make the paths relative as map generation and
          # test run may be executed from different directories
          path.delete_prefix(Rails.root.to_s + "/")
        end

        def trace_path(path)
          return unless path
          # We're not interested in tracing files outside our applicatoin code (e.g. gems or libraries)
          return unless path.start_with?(Rails.root.to_s)
          normalized_path = normalized_path(path)

          # We're not interested in tracing files outside our applicatoin code (e.g. gems or libraries)
          return if normalized_path.start_with?("gems/")
          return if normalized_path.start_with?("vendor/")

          puts normalized_path
        end

        def start
          # We enable the tracepoint before running the first test
          TracePoint.new(:call, :b_call) do |trace_point|
            # Tracepoint#path is the file being executed which is not correct for e.g. included modules or framework code
            # e.g. Article#model would return activemodel-7.0.8/lib/active_model/attribute_methods.rb
            trace_path(trace_point.path)

            # We also need to trace the method receiver to get the correct file for
            # e.g. included modules and framework code.
            # Tracepoint#self is the class of the method receiver and
            # Object.const_source_location returns the file where the class is defined
            trace_path(Object.const_source_location(trace_point.self.class.to_s).first)
          rescue
            # noop
          end.enable
        end

        def prerecord(klass, name)
          puts "==== Starting #{klass}##{name}"
        end

        def record(result); end

        def report; end
      end
    end
  end
end
