module Morrow::Command::PrettyPrint
  extend Morrow::Command

  class << self
    # Print the internal state of any entity
    #
    # Syntax: pp, pp <entity>, pp <keywords>
    #
    def pp(actor, target)
      location = entity_location(actor)
      target ||= location
      target = actor if target == 'self'

      unless entity_exists?(target)
        all = [
          get_component(location, :container)&.contents,
          get_component(actor, :container)&.contents,
          entities
        ].compact.flatten

        target = match_keyword(target, all) or
            raise Morrow::UnknownEntity
      end

      buf = { entity: target, components: entity_components(target) }
          .pretty_inspect
      buf = CodeRay.scan(buf, :ruby).term if player_config(actor, :color)

      send_to_char(char: actor, buf: buf.chomp)
    rescue Morrow::UnknownEntity
      command_error 'That does not exist in the world'
    end
  end
end
