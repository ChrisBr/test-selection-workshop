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
  # We're not interested in tracing files outside our applicatoin code (e.g. gems or libraries)
  return unless path.start_with?(Rails.root.to_s)
  normalized_path = normalized_path(path)

  # We're not interested in tracing files outside our applicatoin code (e.g. gems or libraries)
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
