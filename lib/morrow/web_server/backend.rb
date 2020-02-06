require 'sinatra/base'
require 'rack/contrib/post_body_content_type_parser'
require 'rack/deflater'
require 'json'

# Class for handling v1 API calls
class Morrow::WebServer::Backend < Sinatra::Base
  include Morrow::Logging

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
    response.headers['Access-Control-Allow-Origin'] = '*' unless
        settings.production?
  end

  # pre-flight OPTIONS query; basically say everything is ok for now.  Probably
  # need to do something special once we get JWT auth working.
  options '*' do
    response.headers['Allow'] = 'GET,PUT,POST,DELETE,OPTIONS'
    response.headers['Access-Control-Allow-Headers'] =
        'Authorization, Content-Type, Accept, X-User-Email, X-Auth-Token'
    200
  end
end
