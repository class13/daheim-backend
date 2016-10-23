# myapp.rb
require 'sinatra'
require 'sinatra/reloader' if development?

require 'sinatra/json'
require 'data_mapper'
require 'rubygems'
require  'dm-migrations'

# Loads pre-defined DB Model!
require './model.rb'
#Setup DB
DataMapper.setup(:default, 'mysql://root:14081996@127.0.0.1/daheim1')
DataMapper.finalize
DataMapper.auto_upgrade!

User.all(:status_id => 0).destroy 