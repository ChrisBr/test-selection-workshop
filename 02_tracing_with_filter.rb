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
