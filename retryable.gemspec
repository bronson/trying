# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "retryable"
  s.version = "0.9.0"

  s.files = ["README.markdown", "retryable.gemspec", "lib/retryable.rb"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.3.7"
  s.summary = "Run a code block and retry when an exception occurs."

  s.add_development_dependency "rspec", [">= 0"]
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
end
