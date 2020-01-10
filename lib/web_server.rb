require 'sinatra/base'
require 'faye/websocket'
Faye::WebSocket.load_adapter('thin')
require 'json'
require 'rack/deflater'

require_relative 'world'

class WebServer < Sinatra::Base
  # point the public directory at our static content
  set :public_folder, File.join(File.dirname(__FILE__), '../public')

  # the docs claim that setting this to :after_handler will allow the handler
  # to run, and show the pretty sinatra exception page.  That's a lie, and it's
  # too much hassle for me to debug right now.  We want all the exceptions to
  # go into the central exception list for pry to debug, which is WAY more
  # useful than a pretty webpage.
  set :show_exceptions, false
  set :dump_errors, false

  use Rack::Deflater

  error do
    ex = env['sinatra.error']
    World.log_exception(ex)
    "Exception occurred: #{ex.inspect}"
  end

  before do
    # XXX dev only to allow node web served content to use ajax to query the
    # real server.
    response.headers['Access-Control-Allow-Origin'] = 'http://localhost:5100'
  end

  get '/' do
    send_file File.expand_path('index.html', settings.public_folder)
  end

  get '/api/v1/entities' do
    content_type :json
    q = Regexp.new(params['q']) if params.has_key?('q')
    entities = World.entities.keys
    entities.reject! { |e| e !~ q }
    entities.to_json
  end

  get '/api/v1/entity/*' do |id|
    halt 404 unless World.entity_exists?(id)

    content_type :json
    out = { entity: id, components: [] }
    World.entity_components(id).flatten.each do |comp|
      out[:components] << {
        name: World.component_name(comp),
        fields: comp.to_h,
      }
    end
    out.to_json
  end

  get '/ws/:entity' do
    halt 400 unless Faye::WebSocket.websocket?(request.env)
    halt 404 unless World.entity_exists?(params['entity'])

    # XXX need to write more of this
  end
end
