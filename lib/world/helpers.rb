require 'forwardable'
require 'facets/string/indent'

# World::Helpers
module World::Helpers
  include Helpers::Logging
  include World::ScriptSafeHelpers

  # player_prompt
  #
  # Generate a player prompt
  def player_prompt(entity)
    config = get_component(entity, PlayerConfigComponent)

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

      base_entity = World.entity_manager.create_entity(base: base)
      begin
        base_comps = World.entity_manager.entities[base_entity]
        comps = World.entity_manager.entities[entity]
        comps.zip(base_comps) do |mine, other|
          if other && !mine
            record[:remove] << component_name(other).to_s
          end

          next unless mine

          if mine.is_a?(Array)
            (mine - other).each do |comp|
              record[:components] <<
                  { component_name(comp).to_s => comp.get_modified_fields }
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
        World.entity_manager.destroy_entity(base_entity)
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
  def load_entities(path, area: nil)
    info "loading entities from #{path}"
    loader = World::Loader.new(World.entity_manager)
    loader.load(path: path, area: area)
    loader.finish
  end
  #
  # Call any on_enter scripts defined on location
  def call_on_exit_scripts(location: nil, actor: nil)
    fault 'no actor' unless actor
    fault 'no location' unless location

    get_components(location, :on_exit).each do |trig|
      call_script(trig.script, entity: location, actor: actor)
    end
  end

  # fire_hooks
  #
  # Call any scripts associated with the hook event on this entity
  #
  # Returns:
  #   true: one of the scripts returned :deny
  #   false: no script returned :deny
  def fire_hooks(entity, event, args={})
    get_components(entity, :hook).each do |hook|
      next unless hook.event == event
      result = call_script(hook.script, args)
      return true if result == :deny
    end
    false   # not denied
  end

  # call_script
  #
  # Call the script on the supplied entity
  def call_script(script_id, p={})
    script = get_component(script_id, :script) or
        fault "no script component in #{script_id}"
    fault "#{script_id} script component is empty" unless script.script
    script.script.call(p)
  end
end
