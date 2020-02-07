# Morrow

![run rspec](https://github.com/dmlary/morrow-mud/workflows/run%20rspec/badge.svg)

Ruby implementation of an ECS-based MUD server.

This codebase is in a pre-alpha state; all APIs are likely to change.  You
should not use this gem, but feel free to poke around.

## Features
* Entity-Component-System Architecture
* Telnet server
* Web server
    * Administrative Entity Editor
    * TODO: Builder's Interface
    * TODO: Player's Interface
* Scripting in sandboxed ruby

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'morrow'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install morrow

## Usage

To start the stock server in production mode, with telnet & web server

    $ APP_ENV="production" bundle exec morrow serve

To run the server with all manner of customizations:

```ruby
require 'morrow'

Morrow.run do |c|
  c.host = '0.0.0.0'    # bind to all IPs on this host
  c.telnet_port = 6000  # listen on port 6000 for telnet connections

  c.telnet_login_handler = CustomLoginHandler
                        # Use a custom login handler

  c.http_port = 6010    # listen on port 6010 for http connections
  c.http_port = nil     # or disable the web server

  # override where the mud will load/store data
  c.data_dir   = './data'
  c.player_dir = './data/player.d'
  c.area_dir   = './data/area.d'

  # Do not load the stock world (templates, rooms, items, etc)
  c.load_stock = false

  # Add additional systems to the mud
  c.systems << MyMud::AuctionSystem

  # Replace all the systems in the mud
  c.systems = [ MyMud::CombatSystem, MyMud::AuctionSystem ]
end
```

### Expanding Morrow

Additional components and Systems can be easily added to Morrow

```ruby
module Poison

  # Create a custom Component for tracking Poison
  class Component < Morrow::Component
    field :damage, type: Numeric, desc: 'amount of damage to do'
    field :frequency, type: Numeric, desc: 'frequency of damage'
    field :next_tick, type: Time, desc: 'next time damage should occur'
    field :ticks, type: Integer, desc: 'number of ticks remaining'
  end

  # Create a System for performing updates to entities that are poisoned.
  module System < Morrow::System

    # Create a view of all entities that are poisoned and have health (buried
    # in the resources Component)
    def self.view
      @view ||= Morrow.get_view(all: [ :poisoned, :resources ])
    end

    # Each update of the world, this method will be called for any entity that
    # has both the poisoned component, and the resources component.  The order
    # of the arguments is the same as the order of the Morrow#get_view call
    # above.
    def self.update(entity, poison, resources)
      now = Time.now
      next if poison.next_update > now

      send_to_char(entity, 'You feel the poison burning in your veins.')
      resources.health -= poison.damage
      if (poison.ticks -= 1) == 0
        remove_component(entity, poison)
      else
        poison.next_tick += poison.frequency
      end
    end
  end

  # We'll need a command to poison things!
  def do_poison(actor, arg=nil)
    unless victim = match_keyword(arg, animate_entities(actor))
      send_to_char(actor, "They're not here to be poisoned.")
      return
    end

    if rand(100) < 5    # or, you know, do a real skill check
      send_to_char(actor, "You failed to poison them!")
      send_to_char(victim, "You feel momentarily ill, but the feeling passes.")
      return
    end

    args = { damage: 1, frequency: 6, ticks: 10, next_tick: Time.now + 6 }
    add_component(victim, poison: args)
    send_to_char(actor, '$n turns green as your poison takes hold.')
    send_to_char(victom, "You feel $n's poison seep into your veins.")
  end
end

# Start up the server, and add the poison
Morrow.run do |c|
  c.components[:poison] = Poisoned
  c.systems << PoisonSystem
  c.command[:poison] = Poison.method(:do_poison)
end
```

## Development

You will need the following software installed to do development on Morrow.
* `bundler`
* `npm`: only needed to make changes to the web interface

Once these dependencies are installed, and checking out the repo, run
`bin/setup` to install the remaining dependencies.

The tests can be run by using `rake spec`.

You can also run `bin/morrow console` for an interactive prompt without running
the server that will allow you to experiment.

### Web Interface
To work on the Vue.js web-interface, it's best to run both morrow, and the npm
webpack server in separate windows:

    $ ./bin/morrow serve
    $ npm run serve

Use the URL reported by `npm` to view the latest web-interface.  Both servers
will need to be up, as the interface served by npm will query the Morrow web
server.

### Building a release
To build a production release, `rake build`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/dmlary/morrow.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
