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

def return_response(success, data)
  return json({:success => success}.merge(data))
end

def return_error(error)
  return return_response(false, {:error => error})
end

def return_success(data = {})
  return return_response true, data
end

def create_uuid
  uuid = ""
  loop do 
    uuid = SecureRandom.uuid
    break if User.where('uuid' => uuid).empty?
  end 
  return uuid
end

def put_user 
  validate_not_null ['uuid']
  @user = User.find_by :uuid => @params['uuid']
  if @user.nil?
    raise "access denied"
  end
end

def put_home
  validate_not_null ['bssid']
  bssid = @params['bssid']
  @home = Home.find_by :bssid => bssid
  if @home.nil?
    raise "no home found"
  end
end

def put_home_optional
  validate_not_null ['bssid']
  bssid = @params['bssid']
  @home = Home.find_by :bssid => bssid
end

def put_home_detail_optional
    @home_detail = HomeDetail.find_by :bssid => @params['bssid']
end

def build_home
  validate_not_null ['bssid', 'name']
  @home = Home.new :bssid => @params['bssid'], :name => @params['name']
end

def put_home_of_user
  @home = Home.find @user.home
  if @home.nil?
    raise "no home"
  end
end

def is_int(field_array)
	field_array.each do |f|
		unless @params[f].is_a? Integer
		raise 'invalid parameter ' + f
		end
	end
end

post '/create-user' do
  begin
    validate_not_null ['name']
    name = @params['name']
    uuid = create_uuid
    User.create({:name => name, :uuid => uuid})
    return return_success :uuid => uuid
  rescue Exception => e
    return return_error e.message
  end
end


post '/join-home' do
  begin
    validate_not_null ['bssid', 'uuid']
    put_user
    put_home
    #join
    @user.update({:home => @home.id})
    #response
    return return_success
  rescue Exception => e
    return return_error e.message
  end
end


post '/create-home' do
  #request validation
  begin

    validate_not_null ['bssid', 'name', 'uuid']
    put_user
    build_home
    unless (Home.find_by :bssid => @params['bssid']).nil?
      raise 'home already exists'
    end
    @home.save
    @user.update :home => @home.id
    return return_success
  rescue Exception => error
    return return_error error.message
  end
end

post '/check-home' do
  begin
    validate_not_null ['bssid', 'uuid']
    put_user
    put_home_detail_optional
    unless @home_detail.nil?
      home = {:name => @home_detail.name, :user => @home_detail.user}
    end
    return return_success :home => home
  rescue Exception => e
    return return_error e.message
  end
end


post '/show-home' do
  begin
    validate_not_null ['uuid']
    put_user
    put_home_of_user
    users = []
    users = Memberstatus.where(:home => @home.id).collect{|m| {:name => m.NAME, :status => m.STATUS}}
    return return_success :home_name => @home.name, :users => users
  rescue Exception =>  e
    return return_error e.message
  end
end

post '/set-status' do
	begin
		validate_not_null ['uuid', 'status']
		is_int ['status']
		put_user
		@user.update :status => @params['status']
		return return_success
	rescue Exception =>  e
		return return_error e.message
	end
end

