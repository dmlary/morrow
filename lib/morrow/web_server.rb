require 'rack'

# We construct a specific Rack app that serves everything statically, except
# for /api/v1, which goes to the sinatra app.  It's done this was because I
# didn't see a sufficiently eloquent way to serve the static files, and
# redirect '/' paths to 'index.html' when the user wants to use their own
# public_html directory.
#
# Note that changes to this class **are not** automatically applied when
# this file changes in development mode.  Only changes to the API
module Morrow::WebServer
  class << self
    def app
      Rack::Builder.new do

        # globally, let's use gzip

        # bounce all api request to the sinatra app
        map '/api/v1' do
          run Backend
        end

        # everything else, try to serve as a static file, and default to
        # 'index.html' if no file was provided.
        use Rack::Static, urls: [''], root: Morrow.config.public_html,
            index: 'index.html'

        # this is required to rack doesn't yell that there's no `run`, despite
        # the fact that this will never be called.
        run lambda { 404 }
      end
    end
  end
end

require_relative 'web_server/backend'
