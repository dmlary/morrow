#!/usr/bin/env ruby

require 'yaml'
require 'pp'
require 'pry'
require 'pry-rescue'
require 'memory_profiler'
require_relative '../lib/world'

include World::Helpers

class Bitmask
  def initialize(map={})
    @map = map
  end

  def decode(value)
    value = value.to_i(0) if value.is_a?(String)
    @map.inject([]) { |o,(k,v)| o << v if (value & k) == k; o }
  end
end

SECT = %i{ inside city field forest hills mountains water_swim water_noswim air
            underwater desert teleport }
TELE = Bitmask.new(
  (1 << 0) => :look,
  (1 << 1) => :count,
  (1 << 2) => :random,
  (1 << 3) => :spin)

RoomFlags = Bitmask.new(
  (1 << 0) => :dark,
  (1 << 1) => :death,
  (1 << 2) => :no_mob,
  (1 << 3) => :peaceful,
  (1 << 4) => :no_steal,
  (1 << 5) => :no_travel_out,
  (1 << 6) => :no_magic,
  (1 << 7) => :no_travel_in,
  (1 << 8) => :silence,
  (1 << 9) => :no_push,
  (1 << 10) => :immort_rm,
  (1 << 11) => :god_rm,
  (1 << 12) => :no_recall,
  (1 << 13) => :damroom,
  (1 << 14) => :mobroom,
  (1 << 15) => :no_scry,
  (1 << 16) => :no_purge,
  (1 << 17) => :vamp_rm,
  (1 << 18) => :drak_rm)

EX = Bitmask.new(
  (1 << 0) => :isdoor,
  (1 << 1) => :closed,
  (1 << 2) => :locked,
  (1 << 3) => :secret,
  (1 << 4) => :hidden,
  (1 << 5) => :pickproof
)

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
    get_component!(room, :viewable).desc  = match[:desc].chomp


    env = get_component!(room, :environment)
    numbers = match[:so_many_numbers].scan(/-?\d+/).map(&:to_i)
    room_flags = RoomFlags.decode(numbers[1])
    env.light = 0 if room_flags.include?(:dark)

    case terrain = SECT[numbers[2]]
    when :teleport
      debug "unsupported teleport in #{room}; #{numbers}"
    when Symbol
      env.terrain = terrain
    else
      debug "unknown terrain in #{room}: #{numbers}"
    end

    # let's connect some rooms
    match[:aux] and match[:aux].scan(d_pattern) do
      exit_match = $~
      dest = exit_match[:dest]
      dir  = dirs[exit_match[:dir].to_i]
      passage = "#{room}/passage/#{dir}-to-#{dest}"
      create_entity(id: passage, base: 'base:exit')
      get_component!(passage, :destination).entity = "wbr:room/#{dest}"
      get_component!(passage, :keywords).words = [dirs[exit_match[:dir].to_i]]
      get_component!(room, :exits).list << passage
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
