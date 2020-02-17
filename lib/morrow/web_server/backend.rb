require 'sinatra/base'
require 'rack/contrib/post_body_content_type_parser'
require 'rack/deflater'
require 'json'

# Class for handling v1 API calls
class Morrow::WebServer::Backend < Sinatra::Base
  include Morrow::Helpers

  use Rack::Deflater
  use Rack::PostBodyContentTypeParser

  # Custom error handling to shove all web errors into the central exception
  # queue for debugging.
  set :show_exceptions, false
  set :dump_errors, false
  error do
    ex = env['sinatra.error']
    log_exception(ex)
    settings.production? ? halt(500) : "Exception occurred: #{ex.inspect}"
  end

  before do
    content_type :json
    response.headers['Access-Control-Allow-Origin'] = '*' unless
        settings.production?
  end

  # pre-flight OPTIONS query; basically say everything is ok for now.  Probably
  # need to do something special once we get JWT auth working.
  options '*' do
    # response.headers['Allow'] = 
    response.headers['Access-Control-Allow-Methods'] =
        'GET,PUT,POST,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Headers'] =
        'Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token'
    200
  end

  # GET /entities
  # GET /entities?q=word
  # GET /entities?q=<regexp>
  get '/entities' do
    if q = params['q']
      pattern = Regexp.new(q)
      entities.select { |e| e =~ pattern }
    else
      entities
    end.to_json
  end

  post '/entities' do
    [ 201, { entity: create_entity }.to_json ]
  end

  get '/entities/*' do |entity|
    { entity: entity,
      components: entity_components(entity).map { |c| c.__id__ } }.to_json
  rescue Morrow::UnknownEntity
    halt 404
  end

  get '/components/:id' do |id|
    comp = ObjectSpace._id2ref(id.to_i)
    halt 404 unless comp.kind_of?(Morrow::Component)
    out = {
      component: comp.__id__,
      type: component_name(comp),
      desc: comp.class.desc,
      fields: {} }

    mods = comp.get_modified_fields
    comp.class.fields.each do |field, details|
      h = out[:fields][field] = details.clone
      h[:value] = comp[field]
      h[:modified] = mods.has_key?(field)
    end

    out.to_json
  rescue RangeError
    halt 404
  end

  put '/components/:id/:field' do |id, field|
    comp = ObjectSpace._id2ref(id.to_i)
    halt 404 unless comp.kind_of?(Morrow::Component)
    comp[field] = params['value']
    200
  rescue RangeError, KeyError
    halt 404
  rescue Exception => ex
    halt 422, ex.message
  end
end
