
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "morrow/version"

Gem::Specification.new do |spec|
  spec.name          = "morrow"
  spec.version       = Morrow::VERSION
  spec.authors       = ["David M. Lary"]
  spec.email         = ["dmlary@gmail.com"]

  spec.summary       = <<~SUMMARY
    Ruby implementation of an ECS-based MUD server
  SUMMARY
  spec.homepage      = 'http://github.com/dmlary/morrow'
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = spec.homepage
    spec.metadata["changelog_uri"] = spec.homepage + '/CHANGELOG.md'
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir.chdir(File.dirname(__FILE__)) do
    gemignore = File.readlines('.gemignore').map(&:chomp)
    (%x{ git ls-files -z } + %x{ [ -d dist ] && find dist -type f -print0 })
        .split("\0")
        .reject { |f| gemignore.find { |p| File.fnmatch(p, f) } }
  end

  spec.executables   = 'morrow'
  spec.require_paths = ["lib"]

  spec.add_dependency 'eventmachine', '~> 1.2'
  spec.add_dependency 'colorize'
  spec.add_dependency 'facets', '~> 3'
  spec.add_dependency 'parser', '~> 2.7'
  spec.add_dependency 'thor'
  spec.add_dependency 'bcrypt'
  spec.add_dependency 'method_source'

  # used in Morrow::Helpers::Scriptable.act() to conjugate verbs
  spec.add_dependency 'linguistics'

  spec.add_dependency 'pry'
  spec.add_dependency 'pry-rescue'
  spec.add_dependency 'pry-stack_explorer'

  # breaking change in 2.2 of rack; thin server won't start
  spec.add_dependency 'rack', '>= 2.1.4'
  spec.add_dependency 'thin', '~> 1'
  spec.add_dependency 'sinatra', '~> 2'
  spec.add_dependency 'rack-contrib', '~> 2'

  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rspec-mocks", "~> 3.0"
  spec.add_development_dependency "rspec-parameterized"
  spec.add_development_dependency "yard", "~> 0.9"
  spec.add_development_dependency "memory_profiler", "~> 0.9"
end
