# frozen_string_literal: true

require "test_helper"

class ChapterOneTest < Minitest::Test
  def test_raw_map_generation
    with_raw_map do |raw_map|
      expected = JSON.parse(File.read(File.join(__dir__, "../fixtures/raw_map.json")))
      expected.each do |path, traces|
        refute_nil raw_map[path], "Expected #{path} to be in the raw map"
        assert_equal traces.sort, raw_map[path].sort
      end
    end
  end

  def test_reverse_map_generation
    with_reverse_map do |reverse_map|
      expected = JSON.parse(File.read(File.join(__dir__, "../fixtures/reverse_map.json")))
      expected.each do |path, tests_to_run|
        refute_nil reverse_map[path], "Expected #{path} to be in the reverse map"
        assert_equal tests_to_run.sort, reverse_map[path].sort
      end
    end
  end

  private

  def with_raw_map
    record_map do |raw_map_path, _|
      assert File.exist?(raw_map_path), "Raw test map not found"

      yield JSON.parse(File.read(raw_map_path))
    end
  end

  def with_reverse_map
    record_map do |_, reverse_map_path|
      assert File.exist?(reverse_map_path), "Reverse test map not found"

      yield JSON.parse(File.read(reverse_map_path))
    end
  end

  def record_map
    Dir.mktmpdir do |tmpdir|
      in_rails_root do
        cmd = "bin/rails test --select-record=#{tmpdir} test/**/*_test.rb"
        puts
        puts "Running: #{cmd}"
        out, _ = capture_subprocess_io do
          result = system(cmd)
          assert(result, "Failed to record test map")
        end
        assert_includes(out, "23 runs, 35 assertions, 0 failures, 0 errors, 0 skips")

        yield File.join(tmpdir, "raw_test_map.json"), File.join(tmpdir, "test_map.json")
      end
    end
  end

  def in_rails_root
    Dir.chdir(File.join(__dir__, "../../../..")) do
      yield
    end
  end
end
