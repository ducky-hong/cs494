require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
require 'active_record'

ActiveRecord::Base.configurations = YAML.load(ERB.new(File.read('database.yml')).result)
ActiveRecord::Base.establish_connection(:development)

class User < ActiveRecord::Base; end

arcus = Dalli::Client.new("#{ENV['ARCUS_HOST']}:11211")
nbase_arc = Redis.new(host: "#{ENV['NBASE_ARC_HOST']}", port: 6000)

get '/mysql' do
  user = User.find(1)
  User.clear_all_connections!
  user.to_json
end

get '/arcus' do
  user_cached = arcus.get('user:1')
  if user_cached.nil?
    user_json = User.find(1).to_json
    User.clear_all_connections!
    arcus.set('user:1', user_json)
    user_json
  else
    user_json = JSON.parse(user_cached)
    user_json[:cached] = true
    user_json.to_json
  end
end

get '/nbase-arc' do
  user_cached = nbase_arc.get('user:1')
  if user_cached.nil?
    user_json = User.find(1).to_json
    User.clear_all_connections!
    nbase_arc.set('user:1', user_json)
    user_json
  else
    user_json = JSON.parse(user_cached)
    user_json[:cached] = true
    user_json.to_json
  end
end
