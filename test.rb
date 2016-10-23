ENV['RACK_ENV'] = 'test'

require './daheim.rb'
require 'test/unit'
require 'rack/test'
require 'json'

class DaheimTest < Test::Unit::TestCase
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	def is_json_success(json_text)
		begin
			return JSON.parse(json_text)['success']
		rescue
			return false
		end
	end

	def is_json(json_text)
		begin
			JSON.parse(json_text)
			return true
		rescue
			return false
		end
	end
	def not_nil(obj)
		return !obj.nil?
	end

	def test_use_case_1
		user_name = 'A'
		friend_name = 'B'
		user = nil

		#SETUP
		if not_nil(user = User.get(user_name))
			Wg.all(:admin => user).each{|y| y.members.each{|x| x.update(:wg => nil)}}
			Wg.all(:admin => user).destroy
			User.all(:name => user_name).destroy
		end
		User.all(:name => friend_name).destroy

		#CREATE USER	
		post '/create-user', :name => user_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success" 
		assert not_nil(User.get(user_name)), "User creation failed"

		#CREATE FRIEND1
		post '/create-user', :name => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert not_nil(User.get(friend_name)), "Friend creation failed"

		#CREATE WG
		post '/create-wg', :user => user_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert not_nil(User.get(user_name).wg), "WG creation failed"
		assert_equal User.get(user_name), User.get(user_name).wg.admin, "WG admin set failed"

		#CHANGE NAME OF WG
		post '/change-wg-name', :admin => user_name, :name => "AWG"
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert_equal "AWG", User.get(user_name).wg.name, "name change failed"

		#INVITE FRIEND1
		post '/invite', :inviter =>  user_name, :invitee => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"#+JSON.parse(last_response.body)['error']
		assert not_nil(User.get(user_name).wg), "user.wg nil"
		assert not_nil(User.get(friend_name)), "friend nil"
		assert not_nil(Invite.first(:wg => User.get(user_name).wg, :user => User.get(friend_name))), "Invite creation failed"

		#FRIEND1 SHOWS NEW INVITES
		post '/show-invites', :user => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		invites = JSON.parse(last_response.body)['data']
		assert not_nil(invites), "nil"
		assert_equal user_name, invites[0]['sender'], "sender set failed"
		join_id = invites[0]['id']

		#FRIEND1 JOINS
		post '/join', :user => friend_name, :invite => join_id
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert_nil Invite.get(:wg => User.get(user_name).wg, :user => User.get(friend_name)), "Invite delete failed"
		assert_equal User.get(user_name).wg, User.get(friend_name).wg, "wg join failed"

		#USER CHANGE STATUS
		post '/set-status', :user => user_name, :status => 2
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert_equal 2, User.get(user_name).status.id, "status change failed"

		#SHOW STATUS OF USER 
		post '/show-wg', :user => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		show_wg_result = JSON.parse(last_response.body)
		assert_equal "AWG", show_wg_result['data']['wg'], "Wg NAME SHOW FAILED"
		assert_equal 2, show_wg_result['data']['member'].length, "member count failed"
		assert_equal

		#CLEANUP
		#Gotta destroy that WG
		
	end

	def tes

	# def test_it_say_daheim
	# 	get '/'
	# 	assert last_response.ok?
	# 	assert_equal 'DAHEIM', last_response.body
	# end

	#   #CREATE-WG
	#   #Not exisiting user
	# def test_create_wg_not_existing_user
	# 	user = User.get("simon")
	# 	if !user.nil?
	# 	  user.destroy
	# 	end 
	# 	post '/create-wg', :name => 'simon'
	# 	assert last_response.body.include?("\"success\":false")
	#   end
	#   #Valid user already in a wg
	# def test_create_wg_user_already_wg
	# 	  user = User.new
	# 	  user.name = "simon"
	# 	  user.wg = Wg.new
	# 	  user.save
	# 	  post '/create-wg', :name => 'simon'
	# 	  assert last_response.body.include?("\"success\":false")
	#   end
	#   #Valid
	# def test_create_wg_valid
	# 	  user = User.first_or_create :name => 'simon'
	# 	  user.wg = nil
	# 	  user.save
	# 	  post '/create-wg', :name => 'simon'
	# 	  assert last_response.body.include?("\"success\":true")
	# 	  user = User.get('simon')
	# 	  assert !user.wg.nil?
	#   end
	  
	# def test_create_invite
	# 	inviter = User.first_or_create :name => 'inviter'
	# 	inviter.wg = Wg.new(:admin => inviter)
	# 	inviter.save
	# 	invitee = User.first_or_create :name => 'invitee'
	# 	invitee.wg = nil
	# 	invitee.save

	# 	post '/invite', :inviter => inviter.name, ":invitee" => invitee.name
	# 	assert last_response.body.include?("\"success\":true")
	# 	assert !(Invite.get(inviter.wg.id, invitee.name)).nil?
	#   end
	  
	# def test_show
	# 	  simon = User.first_or_create :name=> "simon"
	# 	  test1 = User.first_or_create :name=> "test1"
	# 	  test2 = User.first_or_create :name=> "test2"
	# 	  puts simon.saved?
	# 	  test1.save
	# 	  test2.save
	# 	  simon.save
	# 	  puts simon.saved?
	# 	  post '/create-wg', :user => test1.name
	# 	  post '/create-wg', :user => test2.name
		  
	# 	  post '/invite', :inviter => test1.name, :invitee => "simon"
	# 	  post '/invite', :inviter => test2.name, :invitee => "simon"
	# 	  puts test2.name
	# 	  post '/show', :user => simon.name
	# 	  puts last_response.body
	# 	  assert !last_response.body == ""
	# end
	# def test_list_user
	# 	  post '/list-user'
	# end
end