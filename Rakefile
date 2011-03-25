require "rubygems"
require "rake/gempackagetask"
require "rake/rdoctask"
require "rspec/core/rake_task"


RSpec::Core::RakeTask.new :spec
task :default => ["spec"]


spec = Gem::Specification.new do |s|
  s.name              = "retryable"
  s.version           = "0.2.0"
  s.summary           = "Runs a code block and retries it when an exception occurs."

  s.has_rdoc          = true
  s.extra_rdoc_files  = %w(README.markdown)
  s.rdoc_options      = %w(--main README.markdown)

  s.files             = %w(README.markdown retryable.gemspec) + Dir.glob("{spec,lib/**/*}")
  s.require_paths     = ["lib"]

  s.add_development_dependency("rspec")
end


# This task actually builds the gem. We also regenerate a static
# .gemspec file, which is useful if something (i.e. GitHub) will
# be automatically building a gem for this project. If you're not
# using GitHub, edit as appropriate.
#
# To publish your gem online, install the 'gemcutter' gem; Read more
# about that here: http://gemcutter.org/pages/gem_docs
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
end


desc "Build the gemspec file #{spec.name}.gemspec"
task :gemspec do
  file = File.dirname(__FILE__) + "/#{spec.name}.gemspec"
  File.open(file, "w") {|f| f << spec.to_ruby }
end

task :package => :gemspec

# Generate documentation
Rake::RDocTask.new do |rd|
  rd.main = "README.markdown"
  rd.rdoc_files.include("README.markdown", "lib/**/*.rb")
  rd.rdoc_dir = "rdoc"
end

desc 'Clear out RDoc and generated packages'
task :clean => [:clobber_rdoc, :clobber_package] do
  rm "#{spec.name}.gemspec"
end
