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

def validate_not_null(field_array)
  field_array.each do |field_name|
    unless @params.has_key?(field_name)
      throw "parameter %s missing" % field_name
    end
  end
end

def return_error(error)
  return json :success => false, :error => error
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

post '/join-home' do
  begin
    validate_not_null ["bssid", "uuid"]
  rescue Exception => e
    return return_error e.ca
  end
  #init
  pssid = @params['bssid']
  uuid = @params['uuid']
  home = Home.find_by({:pssid => pssid})
  user = User.find_by({:uuid => uuid})
  #validate
  error = nil
  if home.nil?
    error = "entry home missing"
  end
  if user.nil?
    error = "entry user missing"
  end
  unless error.nil?
    return return_error error
  end
  #join
  user.update({:home => home})
  #response
  return json :success => true
end

post '/create-home' do
  #request validation
  begin
    validate_not_null ['bssid', 'name', 'uuid']
  rescue Exception => error
    return return_error error.message
  end
  #init
  pssid = @params['bssid']
  name = @params['name']
  uuid = @params['uuid']
  user = User.find_by({:uuid => uuid})
  #valdation
  if user.nil?
    return return_error "entry user missing"
  end
  #creation
  home = Home.create({:pssid => pssid, :name => name})

  #join user 2 group
  user.update({:home => home})
  #response
  return json :success => true
end