require 'rake'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :spec
task :default => ['spec']
task :test => ['spec']

task :build  do
  system 'gem build retryable.gemspec'
end

task :release do
  system 'gem push retryable-*.gem'
end
