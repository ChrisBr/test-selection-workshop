require 'json'
require 'yaml'
require "pathname"
require "fileutils"
require "set"
require "opener"

require_relative "select"
require_relative "select/reporters/map_reporter"
require_relative "select/reporters/simple_reporter"
require_relative "select/reporters/trace_reporter"
require_relative "select/reporters/raw_map_reporter"
require_relative "select/file_filter"
require_relative "select/map_filter"
require_relative "select/changed_files"

# https://github.com/minitest/minitest#writing-extensions-
module Minitest
  class << self
    def plugin_select_options(opts, options)
      if File.exist?(Minitest::Select::DEFAULT_CONFIG_PATH)
        options[:select_config] = YAML.load(File.read(Minitest::Select::DEFAULT_CONFIG_PATH))
      end

      opts.on "--select-simple", "Run simple reporter" do
        options[:select_run] = true
      end
      opts.on "--select-trace", "Run trace reporter" do
        options[:select_trace] = true
      end
      opts.on "--select-open-map", "Open test map" do
        options[:select_open_map] = true
      end
      opts.on "--select-raw=[PATH]", "Run raw map reporter" do |path|
        options[:select_raw] = Pathname.new(path || Minitest::Select::OUTPUT_DIRECTORY)
      end
      opts.on "--select-record=[PATH]", "Create test mapping" do |path|
        options[:select_record_output_directory] = Pathname.new(path || Minitest::Select::OUTPUT_DIRECTORY)
      end
      opts.on "--select-run=[PATH]", "Run test suite based on specified test map" do |path|
        path = path || Minitest::Select::OUTPUT_DIRECTORY.join("test_map.json")
        options[:select_test_map] = JSON.parse(File.read(path)) if File.exist?(path)
      end
      opts.on "--select-file=[PATH]", "Run simple reporter" do |path|
        options[:select_file] = path
      end
      opts.on "--select-config=PATH", "Configuration" do |path|
        options[:select_config] = YAML.parse(File.read(path))
      end
      opts.on "--select-changed-files=[PATH]", "Run test suite based on changed files" do |path|
        options[:select_changed_files] = path&.split(",") || Minitest::Select::ChangedFiles.new.to_a
      end
    end

    def plugin_select_init(options)
      self.reporter << Minitest::Select::Reporters::MapReporter.new(options) if options[:select_record_output_directory]
      self.reporter << Minitest::Select::Reporters::SimpleReporter.new(options) if options[:select_run]
      self.reporter << Minitest::Select::Reporters::TraceReporter.new(options) if options[:select_trace]
      self.reporter << Minitest::Select::Reporters::RawMapReporter.new(options) if options[:select_raw]

      if options[:select_test_map]
        options[:filter] = Minitest::Select::MapFilter.new(
          options[:select_test_map],
          options[:select_config],
          options[:select_changed_files],
        )
      elsif options[:select_file]
        options[:filter] = Minitest::Select::FileFilter.new(options[:select_file])
      end
    end
  end
end
