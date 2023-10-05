# Can be executed with e.g.
# CHANGED_FILES=app/models/comment.rb bin/rails test test/03_run_selected_tests.rb
# CHANGED_FILES=$(git --no-pager diff --merge-base --name-only main) bin/rails test test/03_run_selected_tests.rb

require "json"
require "pathname"

class TestSelection
  ROOT_DIR = Pathname.new(File.dirname(__FILE__) + "/../")
  TEST_MAP_PATH = Pathname.new("tmp/minitest-select/test_map.json")
  ALL_TEST_FILES = Dir[ROOT_DIR.join("test/**/*_test.rb")]

  def self.run
    new.run
  end

  def initialize(env: ENV, config_path: ROOT_DIR.join(".minitest-select.yml"))
    @env = env
    @config = YAML.load(File.read(config_path))
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
    @test_files_to_run ||= begin
      fetch_test_files_to_run + always_select_files + test_files_based_on_glob_rule
    rescue => error
      puts "Error selecting tests: #{error.message}, falling back to all tests"
      ALL_TEST_FILES
    end
  end

  def test_files_based_on_glob_rule
    @config["glob_rules"].flat_map do |entry|
      entry["from"].map do |glob|
        if changed_files.any? { |path| File.fnmatch?(glob, path.squish) }
          entry["to"].map { |to| Dir["#{ROOT_DIR}/#{to}"] }
        end
      end
    end.compact.flatten
  end

  def always_select_files
    @config["always_select"].to_a.map { |file| ROOT_DIR.join(file) } # Convert the test file paths to absolute paths so we can require them
  end

  def fetch_test_files_to_run
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
    @env["CHANGED_FILES"].to_s.lines.map(&:squish) - @config["ignore"].to_a
  end
end

TestSelection.run
