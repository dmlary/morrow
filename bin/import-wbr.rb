#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'pry'
require 'pry-rescue'
require 'memory_profiler'
require_relative '../lib/world'

include World::Helpers

def import_wld(file)
  pattern = %r{
    ^\#(?<vnum>\d+)\s*\n
    (?<title>.*?)~\s*\n
    (?<desc>.*?)~\s*\n
    (?<so_many_numbers>.*?)\n
    (?<aux>^[^S].*?\n)?
    ^S\s*\n
  }mx

  d_pattern = %r{
    ^D(?<dir>\d)\s*\n
    (?<desc>.*?)?~\s*\n
    (?<keyword>.*?)?~\s*\n
    (?<exit_info>\d+)\s*
      (?<key>-?\d+)\s*
      (?<dest>\d+)\s*\n
  }mx
  dirs = %w{ north east south west up down }

  buf = File.read(file)
  vnums = buf.scan(/^#(\d+)$/).flatten
  found = buf.scan(pattern)
  missing = vnums - found.map(&:first)

  test_buf = nil

  unless missing.empty?
    missed = buf.match(/(##{missing.first}$.*?)^#/m)
    test_buf = missed[1]
    pp missed: missed[1]
    pp missing: missing[0,10]
    pp missing: missing.size
    binding.pry
    exit(1)
  end

  buf.scan(pattern) do
    match = $~

    # create the room
    room = "wbr:room/#{match[:vnum]}"
    begin
      create_entity(base: 'base:room', id: room)
    rescue EntityManager::DuplicateId
      error("duplicate room: #{room}; moving old one")
      # So there are duplicate vnums in the world file.  We're just going to
      # clone the old one out of the way; destroy it; then create a clean one
      # for this room.  It's effectively how the old code works.
      old = create_entity(id: room + '-overwritten', base: room)
      get_component(old, :metadata).base = ['base:room']
      destroy_entity(room)
      World.entities.each { |e,_| destroy_entity(e) if e =~ %r{^#{room}/passage/} }
      retry
    end
    get_component!(room, :viewable).short = match[:title]
    get_component!(room, :viewable).desc  = match[:desc]

    # XXX skipping the crazy numbers for the moment

    # let's connect some rooms
    match[:aux] and match[:aux].scan(d_pattern) do
      exit_match = $~
      dest = exit_match[:dest]
      dir  = dirs[exit_match[:dir].to_i]
      passage = "#{room}/passage/#{dir}-to-#{dest}"
      create_entity(id: passage, base: 'base:exit')
      get_component!(passage, :destination).entity = "wbr:room/#{dest}"
      get_component!(passage, :keywords).words = dirs[exit_match[:dir].to_i]
    end
  end

  binding.pry
end

def import(file)
  case file
  when /\.wld$/
    import_wld(file)
  else
    error("unsupported filetype: #{file}")
  end
end

Pry.rescue {
  World.load(File.join(File.dirname(__FILE__), '../data/world'))
  ARGV.each { |f| import(f) }
}
