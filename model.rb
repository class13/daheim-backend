require 'data_mapper'
class User
  include DataMapper::Resource
  property :name, String, :key => true
  property :status_id, Integer, :default => 1
  belongs_to :wg, :required => false
  belongs_to :status, :required => true, :child_key => [:status_id]
  has n,  :invites
end

class Wg
  include DataMapper::Resource
  property :name, String
  property :id, Serial
  has n, :members, 'User'
  has n, :invites
  belongs_to :admin, 'User'
end

class Invite
  include DataMapper::Resource
  property :id, Serial
  belongs_to :wg
  belongs_to :user
end

class Status
  include DataMapper::Resource
  property :name, String
  property :id, Integer, :key => true
  has n,  :users
end