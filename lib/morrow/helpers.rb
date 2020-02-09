require 'facets/hash/deep_rekey'

# A big bucket of helper functions for working with the Entity Component System
# within Morrow.
#
# Helpers fall into two categories: Scriptable, and Non-Scriptable.
#
# Scriptable helpers are those methods that have been verified do not pose a
# security risk for use via the web-interface for building.  Scriptable helpers
# are implemented in Morrow::Helpers::Scriptable.
#
# Non-scriptable helpers are everything else, which reside in this module,
# Morrow::Helpers.
#
# For most anything you're working on, most likely you'll want to
# extend/include this module to get access to the helpers.
module Morrow::Helpers
  extend Morrow::Logging

  def self.extended(base)
    base.extend(Morrow::Logging)
    base.extend(Morrow::Helpers::Scriptable)
  end

  def self.included(base)
    base.include(Morrow::Logging)
    base.include(Morrow::Helpers::Scriptable)
  end

  # player_prompt
  #
  # Generate a player prompt
  def player_prompt(entity)
    config = get_component(entity, :player_config)

    buf = ''
    buf << "\n" unless config && config.compact
    buf << '> '
    buf << "\xff\xf9" if config && config.send_go_ahead
    buf
  end

  # save_entities
  #
  # Save the supplied entities to a given file
  def save_entities(dest, *entities)
    out = entities.flatten.uniq.map do |entity|
      record = {}
      record[:id] = entity

      meta = get_component(entity, :metadata)
      if base = meta.base
        record[:base] = base
      end
      base ||= []

      record[:remove] = []
      record[:components] = []

      base_entity = Morrow.em.create_entity(base: base)
      begin
        base_comps = Morrow.em.entities[base_entity]
        comps = Morrow.em.entities[entity]
        comps.zip(base_comps) do |mine, other|
          if other && !mine
            record[:remove] << component_name(other).to_s
          end

          next unless mine

          if mine.is_a?(Array)
            (mine - other).each do |comp|
              record[:components] <<
                  { component_name(comp).to_s => comp.to_h }
            end
            (other - mine).each do |comp|
              record[:remove] << {
                component_name(comp).to_s => comp.to_h
              }
            end
          else
            next unless mine.save?
            other ||= mine.class.new
            diff = mine - other
            next if diff.empty?
            record[:components] <<
                { component_name(mine).to_s => diff.rekey { |k| k.to_s } }
          end
        end
      ensure
        Morrow.em.destroy_entity(base_entity)
        base_entity = nil
      end

      record.delete_if { |k,v| v.respond_to?(:empty?) and v.empty? }

      record.deep_rekey { |k| k.to_s }
    end

    tmp = dest + '.tmp'
    bak = dest + '.bak'
    begin
      File.open(tmp, 'w+') { |f| f.write(out.to_yaml) }
      File.rename(dest, bak) if File.exists?(dest)
      File.rename(tmp, dest)
    ensure
      File.unlink(bak) if File.exists?(bak)
      File.unlink(tmp) if File.exists?(tmp)
    end
  end

  # load_entities
  #
  # Load entities from a given file
  def load_entities(path)
    info "loading entities from #{path}"
    loader = Morrow::Loader.new
    loader.load_file(path)
    loader.finalize
  end
end

# Also pull in all the scriptable helpers, and add them to Helpers
require_relative('helpers/scriptable')
Morrow::Helpers.extend(Morrow::Helpers::Scriptable)
