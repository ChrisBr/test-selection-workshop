require "pathname"

module Minitest
  module Select
    OUTPUT_DIRECTORY = Pathname.new("tmp/minitest-select")
    PROJECT_ROOT = defined?(Rails) ? Rails.root.to_s + "/" : File.dirname(__FILE__) + "/../"
    DEFAULT_CONFIG_PATH = File.join(PROJECT_ROOT, ".minitest-select.yml")
  end
end
