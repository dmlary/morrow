source 'https://rubygems.org'

gem 'eventmachine'
gem 'colorize'
gem 'facets'
gem 'parser'    # needed for lib/script.rb

# web stack
gem 'thin'
gem 'sinatra'
gem 'faye-websocket'
gem 'rack-contrib'  # auto-parse json content into params

group :test do
  gem 'rspec'
  gem 'rspec-mocks'
end

group :test, :development do
  gem 'pry'
  gem 'pry-remote'
  gem 'pry-rescue'
  gem 'pry-stack_explorer'
  gem 'memory_profiler'
  gem 'get_process_mem'
  gem 'guard'
  gem 'guard-shell'
  gem 'foreman'
  gem 'rake'
end
