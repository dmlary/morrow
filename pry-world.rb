#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'pry'
require 'pry-rescue'
require 'memory_profiler'
require_relative 'lib/component'
require_relative 'lib/world'

Pry.enable_rescuing!

begin
  Component.import(YAML.load_file('./data/components.yml'))
  World.load('./data/world')
  World.pry
rescue Exception => ex
  Pry.rescued(ex)
end
