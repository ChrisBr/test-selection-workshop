lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "minitest/select/version"

Gem::Specification.new do |s|
  s.name        = 'in_repo-minitest-select'
  s.version     =  Minitest::Select::VERSION
  s.licenses    = ['MIT']
  s.summary     = "Run tests based on the code you've changed."
  s.description = "Run tests based on the code you've changed."
  s.authors     = ["Christian Bruckmayer"]
  s.email       = 'christian@bruckmayer.net'
  s.files       = []
  s.homepage    = 'https://rubygems.org/gems/minitest-select'
  s.metadata    = { "source_code_uri" => "https://github.com/ChrisBr/minitest-select" }
end
