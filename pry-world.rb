#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'pry'
require 'pry-rescue'
require 'memory_profiler'
require_relative 'lib/world'

Pry.enable_rescuing!

begin
  World.load(ARGV[0] || './data/world')
  World.pry
rescue Exception => ex
  Pry.rescued(ex)
end
