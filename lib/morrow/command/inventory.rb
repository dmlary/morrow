module Morrow::Command::Inventory
  extend Morrow::Command

  class << self
    # Display what items your character is carrying.
    #
    # Syntax: inventory
    #
    def inventory(actor, arg)
      contents = visible_ = visible_contents(actor: actor, cont: actor)

      if contents.empty?
        send_to_char(char: actor, buf: 'You are not carrying anything.')
        return
      end

      buf = "&WYou are carrying %d items&0:\n" % contents.size
      contents.each do |entity|
        next if !line = get_component(entity, :viewable).short
        buf << "&c%s&0\n" % [ line ]
      end

      send_to_char(char: actor, buf: buf)
    end
  end
end
