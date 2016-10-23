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
		log = []

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
		log << last_response.body

		#CREATE FRIEND1
		post '/create-user', :name => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert not_nil(User.get(friend_name)), "Friend creation failed"
		log << last_response.body

		#CREATE WG
		post '/create-wg', :user => user_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert not_nil(User.get(user_name).wg), "WG creation failed"
		assert_equal User.get(user_name), User.get(user_name).wg.admin, "WG admin set failed"
		log << last_response.body

		#CHANGE NAME OF WG
		post '/change-wg-name', :admin => user_name, :name => "AWG"
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert_equal "AWG", User.get(user_name).wg.name, "name change failed"
		log << last_response.body

		#INVITE FRIEND1
		post '/invite', :inviter =>  user_name, :invitee => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"#+JSON.parse(last_response.body)['error']
		assert not_nil(User.get(user_name).wg), "user.wg nil"
		assert not_nil(User.get(friend_name)), "friend nil"
		assert not_nil(Invite.first(:wg => User.get(user_name).wg, :user => User.get(friend_name))), "Invite creation failed"
		log << last_response.body

		#FRIEND1 SHOWS NEW INVITES
		post '/show-invites', :user => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		invites = JSON.parse(last_response.body)['data']
		assert not_nil(invites), "nil"
		assert_equal user_name, invites[0]['sender'], "sender set failed"
		join_id = invites[0]['id']
		log << last_response.body

		#FRIEND1 JOINS
		post '/join', :user => friend_name, :invite => join_id
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert_nil Invite.get(:wg => User.get(user_name).wg, :user => User.get(friend_name)), "Invite delete failed"
		assert_equal User.get(user_name).wg, User.get(friend_name).wg, "wg join failed"
		log << last_response.body

		#USER CHANGE STATUS
		post '/set-status', :user => user_name, :status => 2
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		assert_equal 2, User.get(user_name).status.id, "status change failed"
		log << last_response.body

		#SHOW STATUS OF USER 
		post '/show-wg', :user => friend_name
		assert is_json(last_response.body), "no json result"
		assert is_json_success(last_response.body), "no success"
		show_wg_result = JSON.parse(last_response.body)
		assert_equal "AWG", show_wg_result['data']['wg'], "Wg NAME SHOW FAILED"
		assert_equal 2, show_wg_result['data']['member'].length, "member count failed"
		show_wg_result['data']['member'].each {|x| assert not_nil x['status']}
		show_wg_result['data']['member'].each {|x| assert not_nil x['name']}
		show_wg_result['data']['member'].each {|x| assert not_nil(x['admin']), "admin failed"}

		log << last_response.body

		# WRITE LOG
		log_path = "response.log"
		open(log_path, 'w') do |f|
			log.each{ |l| f.write(l + "\n")}
		end	
	end

	def assert_json_failure(body)
		assert is_json(body), "NO JSON RESPONSE"
		assert !is_json_success(body),  "BREACH: " + body
	end

	def test_create_user
		# NO USER
		post '/create-user'
		assert_json_failure last_response.body

		# EXISTING USER
		User.first_or_create(:name => 'A').save
		post '/create-user', :name => 'A'
		assert_json_failure last_response.body
	end

	def test_create_wg
		# NO USER
		post '/create-wg'
		assert_json_failure last_response.body

		#EXISTING WG
		if User.get('A').wg.nil?
			wg = Wg.create :admin => User.get('A')
			User.get('A').update :wg => wg
		end
		post '/create-wg', :user => 'A'
		assert_json_failure last_response.body
	end

	def test_change_wg_name
		# NO USER
		post '/change-wg-name', :name => 'C'
		assert_json_failure(last_response.body)

		# NO USER
		post '/change-wg-name', :user => 'A'
		assert_json_failure(last_response.body)

		#NOT ADMIN
		post '/create-wg', :user => 'B', :name => 'C'
		assert_json_failure(last_response.body)
	end

	def test_list_status
		post '/list-status'
		assert is_json(last_response.body)
		status_json_response = JSON.parse last_response.body
		assert status_json_response['success']
		status_list = status_json_response['data']
		assert status_list.length > 0

		i = 1
		status_list.each do |s|
			assert_equal i, s['id']
			i++
		end
	end
end