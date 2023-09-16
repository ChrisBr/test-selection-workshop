# frozen_string_literal: true

require "test_helper"

class ChapterTwoTest < Minitest::Test
  def test_run_selected_tests
    run_selected_tests(["app/views/comments/_form.html.erb"]) do |out|
      assert_includes out, "8 runs"
      assert_includes out, "CommentsControllerTest#test_should_get_edit"
      assert_includes out, "CommentsControllerTest#test_should_get_new"
      assert_includes out, "CommentsControllerTest#test_should_destroy_comment"
      assert_includes out, "CommentsControllerTest#test_should_create_comment"
      assert_includes out, "CommentsControllerTest#test_should_update_comment"
      assert_includes out, "CommentsTest#test_should_destroy_Comment"
      assert_includes out, "CommentsTest#test_should_update_Comment"
      assert_includes out, "CommentsTest#test_should_create_comment"
    end
  end

  def test_fallback_to_all_tests_when_file_not_found
    run_selected_tests(["not_existent.rb"]) do |out|
      assert_includes out, "23 runs"
    end
  end

  private

  def run_selected_tests(diff)
    in_rails_root do
      cmd = "bin/rails test --verbose --select-run --select-changed-files=#{diff.join(',')} test/**/*_test.rb"
      puts
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
