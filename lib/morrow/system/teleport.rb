# This system is responsible for moving entities that have the teleport
# component added to them.
module Morrow::System::Teleport
  extend Morrow::System

  class << self
    def view
      { all: :teleport }
    end

    def update(entity, teleport)
      if !teleport.time
        remove_component(entity, teleport)
        warn('%s: no teleport time; %s; removed' % [ entity, teleport.to_h ])
        return
      end

      return if teleport.time > now

      teleporter = begin
        get_component(teleport.teleporter, :teleporter)
      rescue Morrow::EntityManager::UnknownId
        remove_component(entity, teleport)
        warn('%s: teleporter id invalid; %s; removed' %
            [ entity, teleport.to_h ])
        return
      end

      if teleporter.nil?
        remove_component(entity, teleport)
        warn('%s: teleporter missing component; %s; removed' %
            [ entity, teleport.to_h ])
        return
      end

      buf = teleporter.to_entity and send_to_char(char: entity, buf: buf)

      move_entity(entity: entity, dest: teleporter.dest, look: teleporter.look)

      run_cmd(entity, 'look') if teleporter.look
    end
  end
end
