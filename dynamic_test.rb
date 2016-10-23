ENV['RACK_ENV'] = 'test'

require './daheim.rb'
require 'test/unit'
require 'rack/test'

class DaheimTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def test_list_user
		  get '/list-user'
	end
end