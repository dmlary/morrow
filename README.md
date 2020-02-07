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

```
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
