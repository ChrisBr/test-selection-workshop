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
