# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{retryable}
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Craig 'The Craif' Mackenzie and Niko Felger"]
  s.date = %q{2010-04-07}
  s.email = %q{developers@songkick.com}
  s.extra_rdoc_files = ["README.markdown"]
  s.files = ["README.markdown", "retryable.gemspec", "spec", "lib/retryable.rb"]
  s.homepage = %q{http://www.songkick.com}
  s.rdoc_options = ["--main", "README.markdown"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.5}
  s.summary = %q{Retrying code blocks on specific errors}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
