# Test Selection Workshop

## Table of Contents

- [Introduction](#introduction)
- [Chapter 0: Setup](#chapter-0-setup)
- [Chapter 1: Test Map](#chapter-1-test-map)
  - [1.1: Tracing](#11-tracing)
  - [1.2: Minitest Reporters](#12-minitest-reporters)
  - [1.3: Reverse Map](#13-reverse-map)
  - [1.4: Commands](#14-commands)
  - [1.5: Caveats](#15-caveats)
- [Chapter 2: Test Selection](#chapter-2-test-selection)
  - [2.1: Minitest Autorun](#21-minitest-autorun)
  - [2.1: Minitest Filter](#22-minitest-filter)
  - [2.2: Test Selection](#23-test-selection)
  - [2.3: Commands](#24-commands)
  - [2.4: Caveats](#25-caveats)
- [Chapter 3: Configuration](#chapter-3-configuration)
  - [3.1: Ignored Files](#31-ignored-files)
  - [3.2: Always Selected Tests](#32-always-selected-tests)
  - [3.3: Glob Rules](#33-glob-rules)
  - [3.4: Task](#34-task)
  - [3.5: Commands](#35-commands)
  - [3.6: Hints](#36-hints)
- [Additional Work](#additional-work)
- [FAQ](#faq)
- [Troubleshooting](#troubleshooting)
- [Credits](#credits)

## Introduction

Welcome to your new job as Ruby programmer at Storeify - a new ecommerce website built in Ruby on Rails!
After you've setup your brand new MacBook, you will meet your new boss to get your first assignment.

Storeify maintains one of the biggest Ruby on Rails applications in the world.
This application has a staggering 300,000 Ruby tests which come with various problems.
The test suite frequently fails with flaky tests, takes a very long time to run and the CI costs are through the roof.

The Storeify team came to the conclusion to implement a new and innovative way to run Rails tests: Test Selection!
Test Selection will allow us to fetch the files changed in a given PR and run only the relevant tests.

```
> git --no-pager diff --merge-base --name-only main
app/models/article.rb
app/controllers/articles_controller.rb
app/views/articles/show.html.erb
```

Given this list of files, we can run only tests which touch those code paths and instead of running 300,000 tests we only run 3000.

Your first task will be to implement this test selection framework called `minitest-select`.
A scaffold app based on the "Getting Started with Rails" guide has already been created for you and can be found in this repository.
And don't panic, we will do this together step by step.

## Chapter 0: Setup

This is a demo Rails app based on the [Getting Started Guide](https://guides.rubyonrails.org/getting_started.html).
Please take a moment to clone and setup the app.
You know if everthing works as expected if you can run the test suite successfully.

```
> git clone https://github.com/ChrisBr/test-selection-workshop.git
> bin/setup
> bin/rails test:all
```

## Chapter 1: Test Map

### 1.1: Tracing

To select the correct tests based on changed files, we first need to know which test maps to which application file.
A very simple example of such a test map is this:

```json
{
  "app/controllers/application_controller.rb": ["test/controllers/articles_controller_test.rb", "test/controllers/comments_controller_test.rb"]
}
```

We will generate this map by tracing method executions of each test.
Tracing involves a specialized use of logging to record information about a program's execution.
It is typically used by programmers for debugging purposes, however, we will use it to generate a map of our test suite.
Luckily, Ruby already comes with tracing functionality: [TracePoint](https://ruby-doc.org/3.2.2/TracePoint.html).
The following code snippet will print a trace point whenever a Ruby method or block will get called.

```ruby
trace = TracePoint.new(:call, :b_call) do |trace_point|
  puts trace_point
end.enable
```

Have a look into [01_tracing.rb](01_tracing.rb) which you can execute with `bin/rails runner 01_tracing.rb`.

```ruby
# Tracing involves a specialized use of logging to record information about a program's execution.
# This information is typically used by programmers for debugging purposes.
# https://ruby-doc.org/3.2.2/TracePoint.html
# We have to specify the events we're interested in otherwise Tracepoint will trace all events.
# call: a Ruby method
# b_call: event hook at block entry
# This script can be executed with: bin/rails runner 01_tracing.rb
TracePoint.new(:call, :b_call) do |trace_point|
  receiver_klass = trace_point.self.class.to_s
  method_name = trace_point.method_id
  definition_path = trace_point.path

  puts "#{receiver_klass}##{method_name}<#{definition_path}>"
end.enable

Article.create(body: "Welcome to Rails World!", title: "Welcome!")
```

Executing this script will print out every file Ruby is running which is **A LOT**.
We're not really interested in most of these files so we should add a filter.
Have a look into [02_tracing_with_filter.rb](02_tracing_with_filter.rb) which you can execute with `bin/rails runner 02_tracing_with_filter.rb`.
This should only print out `app/models/article.rb`.

```ruby
# Tracing involves a specialized use of logging to record information about a program's execution.
# This information is typically used by programmers for debugging purposes.
# https://ruby-doc.org/3.2.2/TracePoint.html
# We have to specify the events we're interested in otherwise Tracepoint will trace all events.
# call: a Ruby method
# b_call: event hook at block entry
# This script can be executed with: bin/rails runner 02_tracing_with_filter.rb

TracePoint.new(:call, :b_call) do |trace_point|
  path = trace_point.path

  # We're not interested in tracing files outside our application code (e.g. gems or libraries)
  next unless path.start_with?(Rails.root.to_s)

  # We need to remove the project root to make the paths relative as map generation and
  # test run may be executed from different directories (e.g. CI and local environment)
  normalized_path = path.delete_prefix(Rails.root.to_s + "/")

  # We're not interested in tracing files outside our application code (e.g. gems or libraries)
  next if normalized_path.start_with?("gems/")
  next if normalized_path.start_with?("vendor/")

  receiver_klass = trace_point.self.class.to_s
  method_name = trace_point.method_id
  definition_path = normalized_path

  puts "#{receiver_klass}##{method_name}<#{definition_path}>"
end.enable

Article.create(body: "Welcome to Rails World!", title: "Welcome!")
```

What happens if we change `Article.create(body: "Welcome to Rails World!", title: "Welcome!")` to `Article.new(body: "Welcome to Rails World!", title: "Welcome!").title`?
Our script suddenly doesn't print anything anymore!

The reason is that we use an ActiveRecord attribute method (`Article#title`) which is not defined in `Article` but in `lib/active_model/attribute_methods.rb`.
`Article` is the method receiver though so we should trace it.
Luckily `Tracepoint#self` gives us access to the method receiver and with `Object.const_source_location` returns the file where the class is defined.

Have a look into [03_tracing_method_receiver.rb](03_tracing_method_receiver.rb) which you can execute with `bin/rails runner 03_tracing_method_receiver.rb`.

```ruby
# Tracing involves a specialized use of logging to record information about a program's execution.
# This information is typically used by programmers for debugging purposes.
# https://ruby-doc.org/3.2.2/TracePoint.html
# We have to specify the events we're interested in otherwise Tracepoint will trace all events.
# call: a Ruby method
# b_call: event hook at block entry
# This script can be executed with: bin/rails runner 03_tracing_method_receiver.rb

TracePoint.new(:call, :b_call) do |trace_point|
  # We also need to trace the method receiver to get the correct file for
  # e.g. included modules and framework code.
  # Tracepoint#self is the class of the method receiver and
  # Object.const_source_location returns the file where the class is defined
  path = Object.const_source_location(trace_point.self.class.to_s).first
  next unless path

  # We're not interested in tracing files outside our application code (e.g. gems or libraries)
  next unless path.start_with?(Rails.root.to_s)

  # We need to remove the project root to make the paths relative as map generation and
  # test run may be executed from different directories (e.g. CI and local environment)
  normalized_path = path.delete_prefix(Rails.root.to_s + "/")

  # We're not interested in tracing files outside our application code (e.g. gems or libraries)
  next if normalized_path.start_with?("gems/")
  next if normalized_path.start_with?("vendor/")

  receiver_klass = trace_point.self.class.to_s
  method_name = trace_point.method_id
  receiver_klass_path = normalized_path
  definition_path = trace_point.path

  puts "#{receiver_klass}##{method_name}<#{receiver_klass_path}> defined in #{definition_path}"
end.enable

# e.g. run bin/rails runner 03_tracing_method_receiver.rb | grep title
Article.new(body: "Welcome to Rails World!", title: "Welcome!").title
```

You can find a combined solution in [04_tracing_combined.rb](04_tracing_combined.rb) which you can execute with `bin/rails runner 04_tracing_combined.rb`.

```ruby
# Tracing involves a specialized use of logging to record information about a program's execution.
# This information is typically used by programmers for debugging purposes.
# https://ruby-doc.org/3.2.2/TracePoint.html
# We have to specify the events we're interested in otherwise Tracepoint will trace all events.
# call: a Ruby method
# b_call: event hook at block entry
# This script can be executed with: bin/rails runner 04_tracing_combined.rb

# We use a set because we only want to trace each file once
require "set"

TRACES = Set.new

def normalized_path(path)
  # We need to remove the project root to make the paths relative as map generation and
  # test run may be executed from different directories
  path.delete_prefix(Rails.root.to_s + "/")
end

def trace_path(path)
  return unless path
  # We're not interested in tracing files outside our application code (e.g. gems or libraries)
  return unless path.start_with?(Rails.root.to_s)
  normalized_path = normalized_path(path)

  # We're not interested in tracing files outside our application code (e.g. gems or libraries)
  return if normalized_path.start_with?("gems/")
  return if normalized_path.start_with?("vendor/")

  TRACES << normalized_path
end

TracePoint.new(:call, :b_call) do |trace_point|
  # Tracepoint#path is the file being executed which is not correct for e.g. included modules or framework code
  # e.g. Article#model would return activemodel-7.0.8/lib/active_model/attribute_methods.rb
  trace_path(trace_point.path)
  # We also need to trace the method receiver to get the correct file for
  # e.g. included modules and framework code.
  # Tracepoint#self is the class of the method receiver and
  # Object.const_source_location returns the file where the class is defined
  trace_path(Object.const_source_location(trace_point.self.class.to_s).first)
end.enable

Article.new(body: "Welcome to Rails World!", title: "Welcome!").title

puts TRACES.to_a.sort
```

Congratulations, you now understand `TracePoint` and we're already one step closer to implementing our test selection framework!

### 1.2: Minitest Reporters

Now as we've learned about method tracing, we need to find a way how to integrate this into our test suite.
Our test selection framework will be implemented as [minitest-plugin](https://github.com/minitest/minitest#writing-extensions-) which is a convenient way to extend Minitest.
This project already comes with a scaffold for our framework which you can find in [gems/minitest-select](gems/minitest-select).

We will use a custom Minitest reporter to hook into the test execution.
If you prefer RSpec over Minitest, a Minitest reporter is essentially a [RSpec formatter](https://rubydoc.info/gems/rspec-core/RSpec/Core/Formatters).
Unfortunately, we won't have time to cover RSpec but the ideas taught in this workshop can be transfered to RSpec too.
A very basic example of a Minitest reporter can be found in [gems/minitest-select/lib/minitest/select/reporters/simple_reporter.rb](gems/minitest-select/lib/minitest/select/reporters/simple_reporter.rb) which you can execute with `bin/rails test --select-simple`.

```ruby
# gems/minitest-select/lib/minitest/select/reporters/simple_reporter.rb
# Can be executed with e.g.
# bin/rails test --select-simple
module Minitest
  module Select
    module Reporters
      class SimpleReporter < Minitest::Reporter
        def initialize(options)
        end

        def start
          puts "SimpleReporter started"
        end

        def prerecord(klass, name)
          puts "Starting #{klass}##{name}"
        end

        def record(result)
          puts "Finished #{result.klass}##{result.name}"
        end

        def report
          puts "SimpleReporter finished"
        end
      end
    end
  end
end
```

This is of course not very useful but if we combine this with method tracing it will be super powerful.
Have a look at the following [TraceReporter](gems/minitest-select/lib/minitest/select/reporters/trace_reporter.rb) which will print out all files touched by a certain test.

```ruby
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
          # We're not interested in tracing files outside our application code (e.g. gems or libraries)
          return unless path.start_with?(Rails.root.to_s)
          normalized_path = normalized_path(path)

          # We're not interested in tracing files outside our application code (e.g. gems or libraries)
          return if normalized_path.start_with?("gems/")
          return if normalized_path.start_with?("vendor/")

          puts normalized_path
        end

        def start
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
```

With this we can now implement our raw test map.

```json
{
  "test/controllers/articles_controller_test.rb": ["app/controllers/application_controller.rb"]
}
```

```ruby
# Can be executed with e.g.
# bin/rails test --select-raw --select-open-map test/**/*_test.rb
# gems/minitest-select/lib/minitest/select/reporters/raw_map_reporter.rb
module Minitest
  module Select
    module Reporters
      class RawMapReporter < Minitest::Reporter
        def initialize(options)
          @output_directory = options[:select_raw]
          FileUtils.mkdir_p(@output_directory)
        end

        def start
          enable_tracing
          # We use a Set to store the traces because we only need to trace each file once
          @traces = Set.new
          @raw_map = {}
        end

        def prerecord(klass, name)
          # We reset the traces for each test
          @traces = Set.new
        end

        def record(result)
          # After each test we store the traces for each test file in our raw map
          path = normalized_path(result.source_location.first)
          @raw_map[path] ||= Set.new
          @raw_map[path] += @traces
        end

        def report
          # After all tests have been executed, we store the raw map in a file
          # Default output is stored in tmp/minitest-select/raw_map.json
          # an example output is available in gems/minitest-select/test/fixtures/raw_map.json
          File.write(@output_directory.join("raw_test_map.json"), prettify(@raw_map))
          Opener.system(@output_directory.join("raw_test_map.json").to_s)
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
      end
    end
  end
end
```

### 1.3: Reverse Map
We now know which test touches which application file.
But what we're actually interested in is which test we have to execute when a certain file changes.
In order to do this, we have to reverse our raw test map.

```json
{
  "test/controllers/articles_controller_test.rb": ["app/controllers/application_controller.rb"],
  "test/controllers/comments_controller_test.rb": ["app/controllers/application_controller.rb"],
}
```

should become

```json
{
  "app/controllers/application_controller.rb": ["test/controllers/articles_controller_test.rb", "test/controllers/comments_controller_test.rb"]
}
```

We can do this in the `report` method which gets executed after all tests have run.
You can find the implementation in [gems/minitest-select/lib/minitest/select/reporters/map_reporter.rb](gems/minitest-select/lib/minitest/select/reporters/map_reporter.rb) which you can run with `bin/rails test --select-record --select-open-map test/**/*_test.rb`.

```ruby
# Can be executed by e.g.
# bin/rails test --select-record --select-open-map test/**/*_test.rb
# gems/minitest-select/lib/minitest/select/reporters/map_reporter.rb
module Minitest
  module Select
    module Reporters
      class MapReporter < Minitest::Reporter
        # ... same as RawMapReporter

        def report
          File.write(@output_directory.join("raw_test_map.json"), prettify(@raw_map))
          # After all tests have been executed, we store the reverse test map in a file
          # Default output is stored in tmp/minitest-select/reverse_map.json
          # an example output is available in gems/minitest-select/test/fixtures/raw_map.json
          File.write(@output_directory.join("test_map.json"), prettify(build_reverse_map))
          Opener.system(@output_directory.join("test_map.json").to_s)
        end

        private

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
```

### 1.4 Commands

```
# Executing tracing scripts
> bin/rails runner 01_tracing.rb
> bin/rails runner 02_tracing_with_filter.rb
> bin/rails runner 03_tracing_method_receiver.rb
> bin/rails runner 04_tracing_combined.rb

# Executing reporters
> bin/rails test --select-simple
> bin/rails test --select-trace test/controllers/articles_controller_test.rb:8
> bin/rails test --select-raw --select-open-map test/**/*_test.rb
> bin/rails test --select-record --select-open-map test/**/*_test.rb

# Executing tests for this chapter
> rake minitest_select:chapter_one
```

### 1.5 Caveats

#### Rotoscope
We actually use the [Rotoscope gem](https://github.com/Shopify/rotoscope) instead of trace point which is a high performance Ruby tracer.

#### Approximation
Please note that this will always just be an approximation and won't be 100% accurate.
This will also only trace Ruby code.
For other file types like translation files, VCR cassettes, fixtures or Java Script we have to use different methods to generate a test map.

#### JSON
For simplification we use JSON as the format for our map.
However, this will not scale very well for large applications.
A better format would be to just 'mimic' your application file structure.
For instance, we could have a `app/controllers/application_controller.rb.txt` file and the content of the file would be
`test/controllers/articles_controller_test.rb` and `test/controllers/comments_controller_test.rb`.
We can now archive and compress the folder and additionally don't need to load and parse the whole map but can just read the files required for the test selection.

#### Merge Command
If you have a large test suite it's likely you have to split executing the test suite accross several runners in parallel.
In this case, you need a merge step which can merge the test mapping from several runners into one.

## Chapter 2: Test Selection

Alright, we've made it to the exciting part — test selection!
Now that we have our handy test map, we can leverage it to run only the tests relevant to our code changes.
This will save us time, money, and prevent unnecessary failures.

There are many different ways how we can run only our selected tests.
In this workshop we will look and two approaches with different pros and cons.

### 2.1: Minitest Autorun

Minitest has a handy feature which we can use to run the selected tests: autorun.
Autorun will basically execute all loaded tests.
This is what Rails does when you e.g. run `bin/rails test test/models/article_test.rb`.

But we can also give it a simple script which will just load more tests.
The simplest possible example is this:

```ruby
# Can get executed with bin/rails test test/01_run_one.rb
# We're making use of Minitest autorun
# which will execute all required tests
# https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L69-L89
# https://github.com/minitest/minitest/blob/master/lib/minitest/test.rb#L69-L81
# https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L341-L343
# https://github.com/minitest/minitest/blob/mster/lib/minitest.rb#L1111-L1116

ROOT_DIR = Pathname.new(File.dirname(__FILE__) + "/../")
require ROOT_DIR.join("test/models/article_test.rb")
```

In this script we can now also dynamically `require` more tests based on our test map.

```ruby
# Can be executed with e.g.
# CHANGED_FILES=app/models/comment.rb bin/rails test test/03_run_selected_tests.rb
# CHANGED_FILES=$(git --no-pager diff --merge-base --name-only main) bin/rails test test/03_run_selected_tests.rb

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
```

This approach has one big advantage as it will only load tests which we actually want to run, it will be a lot faster to boot our application.
However, the disadvantage is that this may introduce certain types of flakyness.

### 2.2: Minitest Filter

Minitest also provides a `--filter` argument which we can leverage for this.
Before executing a test, [Minitest will call this filter with each test](https://github.com/minitest/minitest/blob/6719ad8d8d49779669083f5029ea9a0429c49ff5/lib/minitest.rb#L341-L343), we only have to implement a `===` method.

You can actually try this out by running `bin/rails test -n /Article/ --verbose` which will run all Article tests.

As a simple example, we can implement a filter which will only execute tests which are in the provided file.
The difficult part here is to find the source location of the provided test (`other`).
First we have to split the provided string based on the `#` delimiter to get the klass and method name which we then use to find the source location.

You can execute this filter with `bin/rails test --select-file=test/models/article_test.rb`.

```ruby
# Can be executed by e.g.
# bin/rails test --select-file=test/models/article_test.rb
# gems/minitest-select/lib/minitest/select/file_filter.rb
module Minitest
  module Select
    class FileFilter
      def initialize(expected_path)
        @expected_path = expected_path
      end

      # Minitest calls this method with test_method_name and TestKlass#test_method_name
      # https://github.com/minitest/minitest/blob/master/lib/minitest.rb#L341-L343
      def ===(other)
        # other will either be test_name (test_foo) or Klass#test_name (ArticleTest#test_foo)
        # we're only interested in the full test_id because only this allows us to get the source_location
        return false unless other.include?("#")

        # Minitest only provides a string of the test_id e.g. CommentTest#test_extracts_hashtags
        # We need to split CommentTest#test_extracts_hashtags to get the klass and method name
        # which we can use to find the file which defines the test
        klass, method_name = other.split("#", 2)
        path = klass.constantize.new(method_name).method(method_name).source_location.first
        path = path.delete_prefix(PROJECT_ROOT)

        result = path == @expected_path
        puts "Skipping '#{other}' (not in #{@expected_path})" unless result
        result
      end
    end
  end
end

```

### 2.3: Test Selection

We can now use the test map from the previous chapter to only execute tests based on changed files.

```ruby
def ===(other)
  klass, method_name = other.split("#", 2)

  # https://apidock.com/ruby/Method/source_location
  path, line = klass.constantize.new(method_name).method(method_name).source_location
end
```

In our filter method we can then check if the test is included in our selected test files.

```ruby
# Can be executed by e.g.
# bin/rails test --verbose --select-run --select-changed-files=app/controllers/comments_controller.rb test/**/*_test.rb
# gems/minitest-select/lib/minitest/select/map_filter.rb
module Minitest
  module Select
    class MapFilter
      def initialize(test_map, config, changed_files)
        @test_map = test_map
        @config = config
        @changed_files = changed_files
      end

      # Before executing a test, Minitest will call the filter method with test_name and test_id
      # https://github.com/minitest/minitest/blob/6719ad8d8d49779669083f5029ea9a0429c49ff5/lib/minitest.rb#L341-L343
      def ===(other)
        # other will either be test_name (test_foo) or Klass#test_name (ArticleTest#test_foo)
        # we're only interested in the full test_id because only this allows us to get the source_location
        return false unless other.include?("#")

        # Minitest only provides a string of the test_id e.g. ArticleTest#test_foo
        # We need to split ArticleTest#test_foo to get the klass and method name
        # which we can use to find the file which defines the test
        klass, method_name = other.split("#", 2)
        path = klass.constantize.new(method_name).method(method_name).source_location.first
        path = path.delete_prefix(PROJECT_ROOT)

        test_files_to_run.include?(path)
      rescue => error
        # In case of an error we want to be on the safe side and run all tests
        puts "Error while filtering test #{other}: #{error.message}"
        true
      end

      def test_files_to_run
        @test_files_to_run ||= test_files_to_run_based_on_test_map
      end

      def test_files_to_run_based_on_test_map
        @changed_files.to_a.map do |file|
          @test_map.fetch(file.squish)
        end.flatten
      end
    end
  end
end
```

You can run this code with `bin/rails test --select-run --select-changed-files=app/controllers/comments_controller.rb test/**/*_test.rb`.

### 2.4 Commands

```
# Executing helper scripts
> bin/rails test test/01_run_one.rb
> CHANGED_FILES=app/models/comment.rb bin/rails test test/02_run_selected_tests.rb
> CHANGED_FILES=app/models/comment.rb bin/rails test test/03_run_selected_tests.rb
# Executing test filter
> bin/rails test --select-file=test/models/article_test.rb
> bin/rails test --select-run --select-changed-files=app/controllers/comments_controller.rb test/**/*_test.rb

# Executing tests for this chapter
> rake minitest_select:chapter_two
```

### 2.5 Caveats
#### Changed Files

For the sake of simplification we just pass in a list of changed files.
In reality we would use our VCS (e.g. git) to get the changed files though.
And beside changed files there would also be moved, deleted or added files which we would need to handle differently.

## Chapter 3: Configuration

Now that we have implemented test selection for Ruby files, it's time to make our framework more flexible by introducing a configuration file.
Beside Ruby files our application may include different file types.
This will allow us to customize the behavior of our test selection process and handle different kinds of files.

### Chapter 3.1: Ignored Files

Not all files are relevant for our test suite.
For instance, if we change the `README.md` we may not need to run any tests.

We should allow to ignore files which are specified in a config file in `.minitest-select.yml`.

```yaml
ignore:
  - README.md
```

You can run tests for this task with `rake minitest_select:ignored_files`.

### Chapter 3.2: Always Selected Tests

We may also have some test files which are *super* important and we want to always run, we can specify them in our configuration.

```yaml
always_select:
  - test/system/articles_test.rb
```

You can run tests for this task with `rake minitest_select:always_select`.

### Chapter 3.3: Glob Rules (Hard)

Sometimes we may just want to have a simple glob rule which maps from one file type to certain types of tests.
We don't have a mapping for JavaScript or CSS files for instance but we only want to run system / browser tests if any of these changes.

```ruby
glob_rules:
  # Run all system tests if a JavaScript or Stylesheet changes
  - from:
      - "**/*.js"
      - "**/*.css"
    to:
      - "test/system/**/*_test.rb"

  # Run all tests if an initializer changes
  - from:
      - "config/initializers/*"
    to:
      - "test/**/*_test.rb"
```

You can run tests for this task with `rake minitest_select:glob_rule`.

### 3.4 Task

Implement the `ignore`, `glob_rules` and `always_select` keys specified in the `.minitest-select.yml` config file.

A solution can be found in the [solution branch](https://github.com/ChrisBr/test-selection-workshop/tree/solution).

### 3.5 Commands

```
# Executing test filter
> bin/rails test --select-run --select-changed-files=README.md test/**/*_test.rb

# Executing tests for this chapter
> rake minitest_select:ignored_files
> rake minitest_select:always_select
> rake minitest_select:glob_rule
```

### 3.6 Hints

<details>
  <summary>Reveal 1</summary>

  We can use `File.fnmatch?` to match the glob rules from the config file.

  ```ruby
  def test_files_based_on_glob_rule
    config["glob_rules"].flat_map do |entry|
      entry["from"].map do |glob|
        if changed_files.any? { |path| File.fnmatch?(glob, path.squish) }
          entry["to"].map { |to| Dir["#{Rails.root}/#{to}"] }
        end
      end
    end.compact.flatten
  end
  ```

</details>

## Additional Work

We now have a very minimal version of a test selection framework for Rails.

Here are some ideas how you can further extend it:

* Run the full test suite when a commit has the `[ci full]` prefix
* Implement a Minitest reporter which traces translation files (you have to implement a custom backend for i18n)
* Implement a Minitest reporter which traces VCR cassettes
* Implement a merge command which can merge several test mappings

## FAQ

### Can I use this in production?
This workshop just shows some of the ideas we used to implement test selection.
There are many caveats and short cuts so we were able to give an overview in ~60 minutes.
We don't recommend to run the code from this workshop in production!

### Isn't tracing extremely slow?
Yes, from our experience executing our test suite with tracing enabled is about 3-4 times slower.
However, we only need to generate the test mapping periodically (e.g. on every merge to the main branch) so it doesn't matter too much if it's slower.

### Is test selection 100% safe?
No, test selection will always only be an approximation and never 100% accurate.
We believe an automated test suite is just one (important) part of quality assurance and it's important to also have other QA methods in place like review apps, canary rollouts, monitoring and fast reverts.

### Does test selection really work?
Yes, we run test selection for more than 3 years in our CI now.
On average, we only run about 40% of our test suite (about 120k tests instead of 300k tests) making our CI faster, cheaper and more reliable.

### Why don't you release an Open Source version of your test selection framework?
Our solution is very tailored to our needs and we don't believe it would be very useful to other companies.
This workshop describes some of the ideas we used to implement test selection and may help other companies to go into a similar direction.

## Troubleshooting

### bin/setup fails with 'error occurred while installing puma'

You can try to set the correct OpenSSL path (only valid on MacOS):

```
bundle config build.puma --with-pkg-config=$(brew --prefix openssl@1.1)/lib/pkgconfig
```

## Credits

This workshop wouldn't have been possible without contributions from many people who worked on the implementation of test selection at Shopify including but not limited to:

Jean Boussier, Willem Van Bergen, Eduardo Nunes, Sander Lijbrink, Frederik Dudzik, Jessica Xie, Kim Bilida, Mark Côté, Darren Worral, Dylan Thacker-Smith, Richard Nuno, Nikita Acharya, Samantha Turri, Yasmin Benatti, Zarif Mahfuz, Steph Sachrajda.

Thanks to Lewis Buckley and Karl Entwistle for providing feedback on this workshop.
