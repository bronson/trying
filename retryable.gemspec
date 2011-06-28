# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = 'retryable'
  s.version  = '0.9.0'
  s.authors  = ['Cheah Chu Yeow', 'Carlo Zottmann', 'Songkick', 'Scott Bronson']
  s.email    = ['brons_retryable@rinspin.com']
  s.homepage = 'http://github.com/bronson/retryable'
  s.summary  = 'Run a code block and retry when an exception occurs.'
  s.description = s.summary

  s.files = ['README.markdown', 'retryable.gemspec', 'lib/retryable.rb']
  s.require_paths = ['lib']
  s.add_development_dependency 'rspec', ['>= 2.5']
end
