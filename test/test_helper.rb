ENV['RACK_ENV'] ||= 'test'

require_relative '../syllabus_app'
require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'mocha/mini_test'
require 'rack/test'
require 'webmock/minitest'
require 'zip'

# Turn on SSL for all requests
class Rack::Test::Session
  def default_env
    { 'rack.test' => true,
      'REMOTE_ADDR' => '127.0.0.1',
      'HTTPS' => 'on'
    }.merge(@env).merge(headers_for_env)
  end
end

class Minitest::Test

  include Rack::Test::Methods

  def app
    SyllabusApp
  end

  def setup
    WebMock.enable!
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)
    app.settings.stubs(:api_cache).returns(false)
  end

  def login(session_params = {})
    defaults = {
      'user_id' => '123',
      'user_roles' => ['AccountAdmin'],
      'user_email' => 'test@example.com'
    }

    env 'rack.session', defaults.merge(session_params)
  end
end
