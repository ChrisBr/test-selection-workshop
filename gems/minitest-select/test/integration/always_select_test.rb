# frozen_string_literal: true

require "test_helper"

class AlwaysSelectTest < Minitest::Test
  def test_always_select
    run_selected_tests([]) do |out|
      assert_includes out, "4 runs" # only always select tests
    end
  end

  private

  def run_selected_tests(diff)
    in_rails_root do
      cmd = "bin/rails test --verbose --select-run --select-changed-files=#{diff.join(',')} test/**/*_test.rb"
      puts "Running: #{cmd}"
      out, _ = capture_subprocess_io do
        result = system(cmd)
        assert(result, "Failed to run tests")
      end

      yield out
    end
  end

  def in_rails_root
    Dir.chdir(File.join(__dir__, "../../../..")) do
      yield
    end
  end
end
