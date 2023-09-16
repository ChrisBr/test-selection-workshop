# Can be executed with e.g.
# CHANGED_FILES=app/models/comment.rb bin/rails test test/02_run_selected_tests.rb
# CHANGED_FILES=$(git --no-pager diff --merge-base --name-only main) bin/rails test test/02_run_selected_tests.rb

require "json"
require "pathname"

class TestSelection
  ROOT_DIR = Pathname.new(File.dirname(__FILE__) + "/../")
  TEST_MAP_PATH = Pathname.new("tmp/minitest-select/test_map.json")

  def self.run
    new.run
  end

  def initialize(env: ENV)
    @env = env
  end

  def run
    puts "Selected #{test_files_to_run.join(', ')} files"

    # We're making use of Minitest autorun
    # which will execute all required tests
    # https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L69-L89
    # https://github.com/minitest/minitest/blob/master/lib/minitest/test.rb#L69-L81
    # https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L341-L343
    # https://github.com/minitest/minitest/blob/mster/lib/minitest.rb#L1111-L1116
    test_files_to_run.each do |file|
      require file
    end
  end

  private

  def test_files_to_run
    @test_files_to_run ||= fetch_test_files_to_run
  end

  def fetch_test_files_to_run
    raise "No changed files found" if changed_files.empty?

    # Fetch the tests to run from the test map
    changed_files.to_a.map do |file|
      test_map.fetch(file.squish)
    end.flatten.compact.map { |file| ROOT_DIR.join(file) } # Convert the test file paths to absolute paths so we can require them
  end

  def test_map
    @test_map ||= begin
      raise "No test map found, run 'bin/rails test --select-record --select-open-map test/**/*_test.rb'" unless File.exist?(TEST_MAP_PATH)

      JSON.parse(File.read(TEST_MAP_PATH))
    end
  end

  def changed_files
    @env["CHANGED_FILES"].to_s.lines.map(&:squish)
  end
end

TestSelection.run
