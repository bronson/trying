# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name     = 'trying'
  s.version  = '0.9.8'
  s.authors  = ['Cheah Chu Yeow', 'Carlo Zottmann', 'Songkick', 'Scott Bronson']
  s.email    = ['brons_trying@rinspin.com']
  s.homepage = 'http://github.com/bronson/trying'
  s.summary  = 'Run a block, retry when an exception occurs.'
  s.description = 'Execute the code block until it succeeds.  Punch it until it yields.'

  s.files = ['README.markdown', 'trying.gemspec', 'lib/trying.rb']
  s.require_paths = ['lib']
  s.add_development_dependency 'rspec', ['>= 2.5']
end
