# myapp.rb
require 'sinatra'
require 'sinatra/reloader' if development?
require 'active_record'

require 'sinatra/json'
require 'rubygems'
require 'securerandom'
#require 'rack/contrib'

set :bind, '0.0.0.0'
# Loads pre-defined DB Model!
require './model.rb'
require './connect.rb'

get '/' do
  'DAHEIM'
end

before do
  if request.body.size > 0
    request.body.rewind
    @params = ActiveSupport::JSON.decode(request.body.read)
  end
end

post '/create-user' do
  name = @params['name']
  uuid = ""
  loop do 
    uuid = SecureRandom.uuid
    break if User.where('uuid' => uuid).empty?
  end 
  User.create({:name => name, :uuid => uuid})
  json :success => true, :uuid => uuid
end

post '/build-home' do
  pssid = @params['pssid']
  
end
