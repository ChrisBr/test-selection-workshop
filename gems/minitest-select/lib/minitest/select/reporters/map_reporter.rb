# https://github.com/minitest/minitest#adding-custom-reporters-
# Can be executed with e.g.
# bin/rails test --select-record --select-open-map test/**/*_test.rb
module Minitest
  module Select
    module Reporters
      class MapReporter < Minitest::Reporter
        def initialize(options)
          @options = options
          @output_directory = options[:select_record_output_directory]
          FileUtils.mkdir_p(@output_directory)
        end

        def start
          @traces = Set.new
          enable_tracing
          @raw_map = {}
        end

        def prerecord(klass, name)
          @traces = Set.new
        end

        def record(result)
          path = normalized_path(result.source_location.first)
          @raw_map[path] ||= Set.new
          @raw_map[path] += @traces
        end

        def report
          File.write(@output_directory.join("raw_test_map.json"), prettify(@raw_map))
          # After all tests have been executed, we store the reverse test map in a file
          # Default output is stored in tmp/minitest-select/reverse_map.json
          # an example output is available in gems/minitest-select/test/fixtures/raw_map.json
          File.write(@output_directory.join("test_map.json"), prettify(build_reverse_map))
          Opener.system(@output_directory.join("test_map.json").to_s) if @options[:select_open_map]
        end

        private

        def prettify(map)
          JSON.pretty_generate(map.transform_values(&:to_a))
        end

        def trace_path(path)
          return unless path
          # We're not interested in tracing files outside our application code (e.g. gems or libraries)
          return unless path.start_with?(PROJECT_ROOT)
          normalized_path = normalized_path(path)

          # We're not interested in tracing files outside our application code (e.g. gems or libraries)
          return if normalized_path.start_with?("gems/")
          return if normalized_path.start_with?("vendor/")

          @traces << normalized_path
        end

        def enable_tracing
          TracePoint.new(:call, :b_call) do |trace|
            # Tracepoint#path is the file being executed which is not correct for e.g. included modules or framework code
            # e.g. Article#model would return activemodel-7.0.8/lib/active_model/attribute_methods.rb
            trace_path(trace.path)
            # We also need to trace the method receiver to get the correct file for
            # e.g. included modules and framework code.
            # Tracepoint#self is the class of the method receiver and
            # Object.const_source_location returns the file where the class is defined
            trace_path(Object.const_source_location(trace.self.class.to_s).first)
          rescue
            # noop
          end.enable
        end

        def normalized_path(path)
          # We need to remove the project root to make the paths relative as map generation and
          # test run may be executed from different directories
          path.delete_prefix(Minitest::Select::PROJECT_ROOT)
        end

        def build_reverse_map
          {}.tap do |result|
            @raw_map.each do |test_file, traces|
              traces.each do |path|
                result[path] ||= []
                result[path] << test_file
                result[path].uniq!
              end
            end
          end
        end
      end
    end
  end
end
