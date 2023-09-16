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
