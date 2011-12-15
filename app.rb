require 'sinatra'
require File.dirname(__FILE__) + '/lib/delivery_bus'

configure do
  set :port, 3334
end

post '/deploy' do
  DeliveryBus::Deploy.new.dispatcher(params[:payload])
end

#get '/rollback' do
#  @tags = `cd #{options.app_path} && git tag | grep homolog`.split("\n")
#  erb :rollback
#end
#
#post '/rollback_tag' do
#  @tag_version = params[:tag_version]
#  `cd #{options.app_path} && git add . && git checkout master && git pull && git checkout #{@tag_version} && bundle install && rake db:drop RAILS_ENV=production && rake db:create RAILS_ENV=production && rake db:migrate RAILS_ENV=production && init_unicorn`
#  erb :rollback_tag
#end

