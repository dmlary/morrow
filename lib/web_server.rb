require 'sinatra/base'
require 'faye/websocket'
Faye::WebSocket.load_adapter('thin')
require 'json'
require 'rack/deflater'
require 'rack/contrib/post_body_content_type_parser'

require_relative 'world'

class WebServer < Sinatra::Base
  include Helpers::Logging

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
  use Rack::PostBodyContentTypeParser

  error do
    ex = env['sinatra.error']
    World.log_exception(ex)
    "Exception occurred: #{ex.inspect}"
  end

  # XXX here is all sorts of CORS shit we really don't understand.  This needs
  # to be cleaned up and implemented the correct way.
  configure do
    enable :cross_origin
  end

  before do
    # XXX dev only to allow node web served content to use ajax to query the
    # real server.
    response.headers['Access-Control-Allow-Origin'] = 'http://localhost:8080'
    # response.headers['Access-Control-Allow-Origin'] = request.env['HTTP_REFERER']
  end

  options "*" do
    response.headers["Allow"] = "GET,PUT,POST,DELETE,OPTIONS"
    response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token"
    response.headers["Access-Control-Allow-Origin"] = "*"
    response.headers["Access-Control-Allow-Methods"] = "*"
    200
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
    content_type :json

    halt 404 unless World.entity_exists?(id)

    out = { entity: id, components: [] }

    World.entity_components(id).flatten.each do |comp|

      data = {
        name: World.component_name(comp),
        desc: comp.class.desc,
        unique: comp.unique?,
        id: comp.__id__,
        fields: {},
      }

      mods = comp.get_modified_fields
      comp.class.fields.each do |name,field|
        data[:fields][name] = field
            .merge(value: comp[name], modified: mods.has_key?(name))
      end

      out[:components] << data
    end
    out.to_json
  end

  get '/api/v1/component/*' do |name|
    content_type :json

    comp = Component.find(name) or halt 404
    { name: name, fields: comp.fields, defaults: comp.defaults }.to_json
  end

  put '/api/v1/component/:id/:field' do |id,field|
    content_type :json

    comp = begin
      ObjectSpace._id2ref(id.to_i)
    rescue Exception
      return 404
    end

    return 404 unless comp.kind_of?(Component)

    begin
      comp[field] = params["value"]
    rescue KeyError
      return 404
    rescue Exception => ex
      return 422, ex.message
    end

    return 200
  end

  get '/ws/:entity' do
    halt 400 unless Faye::WebSocket.websocket?(request.env)
    halt 404 unless World.entity_exists?(params['entity'])

    # XXX need to write more of this
  end
end
