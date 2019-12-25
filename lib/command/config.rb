module Command::Config
  extend World::Helpers

  Command.register('config') do |actor, rest|
    fault 'no :config_options found for actor', actor unless
        config = get_component(actor, PlayerConfigComponent)

    key, value = rest.split(/\s+/, 2) if rest
    if key
      raise Command::SyntaxError,
          'value must be true/false or on/off' unless
              value =~ /^(true|on|false|off)(\s|$)/
      value = %w{ true on }.include?($1)
      config.send("#{key}=", value)
      next "&W#{key}&0 = &c#{value}&0\n"
    end

    fields = config.class.defaults.keys
    field_width = fields.map(&:size).max
    buf = "&WConfigration Options:&0\n"
    fields.each do |name|
      buf << "  &W%#{field_width}s&0: &c%s&0\n" % [ name, config.send(name) ]
    end
    buf
  end
end
