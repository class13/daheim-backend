# myapp.rb
require 'sinatra'
require 'sinatra/reloader' if development?

require 'sinatra/json'
require 'data_mapper'
require 'rubygems'
require  'dm-migrations'

set :bind, '0.0.0.0'
# Loads pre-defined DB Model!
require './model.rb'
require './connect.rb'
#Setup DB
DataMapper.setup(:default, $connect_string)
DataMapper.finalize
begin
  if(ENV['RACK_ENV'] == 'test')
    DataMapper.auto_migrate!
  else
    DataMapper.auto_upgrade!
  end
rescue
  abort $connect_string + " is invalid"
end
  
require './status_init.rb'
get '/' do
  'DAHEIM'
end

#TESTED
#Create User
#param name: name for user
post '/create-user' do
  user_name = params['name']
  user = User.get(user_name)
  if user_name.nil?
    return json :success => false, :error => "no parameter"
  end
  unless user.nil?
    return json :success => false, :error => "already exists"
  else
    user = User.create :name => user_name
    return json :success => true
  end
    
end

#Create WG
#param user = name of active user
post '/create-wg' do
  name = params['user']
  user = User.get(name)
  if user.nil?
    return json :success => false, :error => "user not found"
  end
  if user.wg.nil?
    wg = Wg.new
    wg.admin = user
    user.wg = wg
    user.save
    json :success => true
  else
    json :success => false, :error => "existing membership"
  end
  #NICHT MÖGLICH WENN MITGLIED SCHON MITGLIED IST
  #sonst neue WG mit admin this user
  #User WG auf neues setzen
  #refresh json
end

#Change name of wg of
#param admin: name of admin
#to
#param name: new name of wg
post '/change-wg-name' do
  admin = User.get(params['admin'])
  name = params['name']
  if admin.nil? || admin.wg.nil?
    return json :success => false, :error => "invalid user"
  end
  if name.nil? || name == ""
    return json :success => false, :error => "invalid name"
  end
  unless admin.wg.admin == admin
    return json :success => false, :error => "no privilege"
  end

  admin.wg.update :name => name;
  return json :success => true
end

#Invite 
#param invitee: name of invitee
post '/invite' do
    #Init
    inviter = User.get( params['inviter'])
    invitee = User.get(params['invitee'])
    #beide user müssen existieren
    if inviter.nil? || invitee.nil?
      return json :success => false, :error => "user not found"
    end
    #du musst admin deiner wg sein
    if inviter.wg.nil? || inviter.wg.admin != inviter
      return json :success => false, :error => "inviter not admin"
    end
    #erstelle neues invite mit dieser wg und zielname
    invite = Invite.new
    invite.wg = inviter.wg
    invite.user = invitee
    invite.save
    json :success => invite.saved?
end

post '/join' do
  invite = Invite.get(params['invite'])
  # Wenn passendes invite existiert
  if invite.nil?
    return json :success => false, :error => "access denied"
  end
  # User keine WG hat
  if !invite.user.wg.nil?
    return json :success => false, :error => "user is member of differnt wg"
  end
  # Setze user wg diese wg
  invite.user.update(:wg => invite.wg)
  # Lösche invite
  invite.destroy
  # Refresh json
  return json :success => true
end

post '/set-status' do
  # Param: status (home, gone, dont disturb)
  status = Status.get(params['status'])
    if status.nil?
      return json :success => false, :error => "invalid status"
    end
    user = User.get(params['user'])
      if user.nil?
        return json :success => false, :error => "invalid user"
      end
      user.update :status => status
      return json :success => true
  # Setze Status von User
    
end

def user_to_json(user)
  if user.nil?
    return {'name' => "mystery"}
  end
  return {'name' => user.name, 'status' => user.status.name}
end

post '/show-invites' do
  user = User.get(params['user'])
  if user.nil?
        return json :success => false, :error => "invalid user"
  end
  return json :success => true, :data => user.invites.map {|invite| {'sender' => invite.wg.admin.name, 'id' => invite.id}}
end

post '/show-wg' do
  user = User.get(params['user'])
  if user.nil?
    return json :success => false, :error => "invalid user"
  end
  if user.wg.nil?
    return json :success => false, :error => "no membership"
  end
  return json :success => true,  :data => {'wg' => user.wg.name, 'member' => user.wg.members.map {|m| {'name' => m.name, 'status' => m.status.name, 'admin' => m.wg.admin == m}}}
end

post '/list-status' do
  return json :success => true, :data => Status.all
end

#UNTESTED WG HIRACHY SYSTEM
post '/privilege' do
  # Musst admin von seiner WG sein
  actor = User.get(params['actor'])
  target = User.get(params['target'])
        
        if target.nil?
          return json :success => false, :error => "invalid target"
        end
        unless !actor.nil? &&  !target.wg.nil? && target.wg.admin == actor
          return json :success => false, :error => "no privilege"
        end
  # Setze Admin von seiner Wg auf ihn
        target.wg.update :admin => target
        return json :success => true
end

post '/kick' do
    admin = User.get(params['admin'])
    target = User.get(params['target'])
      
      if target.nil?
        return json :success => false, :error => "invalid target"
      end
      unless !admin.nil? &&  !target.wg.nil? && (target.wg.admin == admin || target == admin)
        return json :success => false, :error => "no privilege"
      end
  # Musst Admin von seiner WG sein
  # Setze WG zu null
      target.update :wg => nil
      return json :success => true
end
